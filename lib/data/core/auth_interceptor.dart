import 'package:cuan_app/data/core/token_refresher.dart';
import 'package:cuan_app/data/core/token_storage.dart';
import 'package:dio/dio.dart';

typedef RefreshFn = Future<String?> Function(String refreshToken);

class AuthInterceptor extends Interceptor {
  final TokenStorage storage;
  final RefreshFn onRefresh;

  /// Interceptor standar: kalau kena 401, tukar refresh token (satu panggilan bersama) lalu ulangi.
  AuthInterceptor.withRefresh(this.storage)
    : onRefresh = ((_) => TokenRefresher.refresh(storage));

  // tambahkan holder Dio
  Dio? _dio;
  void attach(Dio dio) => _dio = dio;
  AuthInterceptor({required this.storage, required this.onRefresh});

  static const _retriedKey = 'auth_retried';

  /// Endpoint login/OTP/register tidak boleh memicu refresh: 401 di sana artinya kredensial salah,
  /// dan refresh token yang tersimpan saat itu kosong atau milik sesi lain.
  static bool _skipRefresh(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/otp') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/forgot-password') ||
      path.contains('/auth/reset-password') ||
      path.contains('/auth/check');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await storage.getAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        req.extra[_retriedKey] == true ||
        _skipRefresh(req.path)) {
      handler.next(err);
      return;
    }

    final refresh = await storage.getRefresh();
    if (refresh == null || refresh.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      // Request lain yang 401 bersamaan ikut menunggu refresh yang sama (lihat TokenRefresher)
      final newAccess = await onRefresh(refresh);
      if (newAccess != null) {
        // Tandai supaya request ini tidak masuk lingkaran refresh kalau 401 lagi
        req.extra[_retriedKey] = true;
        req.headers['Authorization'] = 'Bearer $newAccess';

        // pastikan ada Dio (fallback: pakai baseUrl dari request lama)
        final dio = _dio ?? Dio(BaseOptions(baseUrl: req.baseUrl));
        final res = await dio.fetch(req);
        handler.resolve(res);
        return; // penting: stop di sini
      }
    } on DioException catch (e) {
      // pengulangan request gagal (mis. 500): teruskan error aslinya, bukan 401 lama
      handler.next(e);
      return;
    } catch (_) {
      // biarkan jatuh ke handler.next di bawah
    }
    handler.next(err);
  }
}
