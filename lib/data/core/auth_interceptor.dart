import 'package:cuan_app/data/core/token_storage.dart';
import 'package:dio/dio.dart';

typedef RefreshFn = Future<String?> Function(String refreshToken);

class AuthInterceptor extends Interceptor {
  final TokenStorage storage;
  final RefreshFn onRefresh;

  // tambahkan holder Dio
  Dio? _dio;
  void attach(Dio dio) => _dio = dio;
  AuthInterceptor({required this.storage, required this.onRefresh});

  bool _refreshing = false;

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
    if (err.response?.statusCode == 401 && !_refreshing) {
      _refreshing = true;
      try {
        final refresh = await storage.getRefresh();
        if (refresh != null) {
          final newAccess = await onRefresh(refresh);
          if (newAccess != null) {
             // retry dengan Dio yang sama
            final req = err.requestOptions;
            req.headers['Authorization'] = 'Bearer $newAccess';
            
            // pastikan ada Dio (fallback: pakai baseUrl dari request lama)
            final dio = _dio ?? Dio(BaseOptions(baseUrl: req.baseUrl));
            final res = await dio.fetch(req);

            handler.resolve(res);
            return; // penting: stop di sini
          }
        }
      } catch (_) {
        // biarkan jatuh ke handler.next di bawah
      } finally {
        _refreshing = false;
      }
    }
    handler.next(err);
  }
}
