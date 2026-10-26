import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/config/app_config.dart';
import 'package:cuan_app/data/core/token_storage.dart';
import 'package:cuan_app/data/response/refresh_response.dart';
import 'package:dio/dio.dart';

/// Satu-satunya tempat yang menukar refresh token dengan access token baru.
///
/// Single-flight: kalau banyak request kena 401 bersamaan (mis. home membuka puluhan request),
/// semuanya menunggu SATU panggilan /auth/refresh yang sama, lalu masing-masing mengulang request-nya.
class TokenRefresher {
  TokenRefresher._();

  static Future<String?>? _inFlight;

  /// Access token baru, atau null kalau tidak bisa di-refresh.
  /// Token di storage hanya dihapus kalau server MENOLAK refresh token (400/401/403). Gagal karena
  /// jaringan, timeout, 5xx, atau 422 tidak menghapus token, jadi user tidak ter-logout hanya karena
  /// sinyal jelek.
  static Future<String?> refresh(TokenStorage storage, {Dio? client}) {
    return _inFlight ??= _run(storage, client).whenComplete(() => _inFlight = null);
  }

  static Future<String?> _run(TokenStorage storage, Dio? client) async {
    final refreshToken = await storage.getRefresh();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final dio = client ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        );
    try {
      final res = await dio.post(
        ApiPaths.refresh,
        data: {'Refresh_token': refreshToken},
      );
      final rr = RefreshResponse.fromJson(res.data as Map<String, dynamic>);
      await storage.saveTokens(access: rr.accessToken, refresh: refreshToken);
      return rr.accessToken;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 401 || code == 403) await storage.clear();
      return null;
    } catch (_) {
      return null;
    }
  }
}
