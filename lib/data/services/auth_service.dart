import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/data/request/register_request.dart';
import 'package:cuan_app/data/request/update_me_request.dart';
import 'package:cuan_app/data/response/me_response.dart';
import 'package:cuan_app/data/response/refresh_response.dart';
import 'package:cuan_app/data/response/register_response.dart';
import 'package:cuan_app/data/response/token_pair_response.dart';
import 'package:cuan_app/data/response/update_me_response.dart';
import 'package:dio/dio.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/token_storage.dart';

class AuthService {
  final Dio _dio;
  final TokenStorage _storage;

  AuthService._(this._dio, this._storage);

  factory AuthService(TokenStorage storage) {
    // Interceptor butuh fungsi refresh
    final interceptor = AuthInterceptor(
      storage: storage,
      onRefresh: (refreshToken) async {
        try {
          final dio = Dio(BaseOptions(baseUrl: _baseUrlFromApiClient()));
          print(dio);
          final res = await dio.post(
            ApiPaths.refresh,
            data: {'refresh_token': refreshToken},
            // data: {'Refresh_token': refreshToken},
          );
          final rr = RefreshResponse.fromJson(res.data);
          await storage.saveTokens(
            access: rr.accessToken,
            refresh: refreshToken,
          );
          return rr.accessToken;
        } catch (_) {
          await storage.clear();
          return null;
        }
      },
    );
    final dio = ApiClient.instance(interceptor);
    return AuthService._(dio, storage);
  }

  static String _baseUrlFromApiClient() {
    // akses dari BaseOptions (sudah diset di ApiClient)
    return ApiClient.instance(
      AuthInterceptor(storage: TokenStorage(), onRefresh: (_) async => null),
    ).options.baseUrl;
  }

  Future<TokenPairResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      ApiPaths.login,
      data: {'email': email, 'password': password},
    );
    final tp = TokenPairResponse.fromJson(res.data);
    await _storage.saveTokens(access: tp.accessToken, refresh: tp.refreshToken);
    return tp;
  }

  Future<void> logout() async {
    await _storage.clear();
  }

  Future<MeResponse> me() async {
    final res = await _dio.get(ApiPaths.me);
    return MeResponse.fromJson(res.data);
  }

  Future<RegisterResponse> register(RegisterRequest req) async {
    try {
      final res = await _dio.post(ApiPaths.register, data: req.toJson());
      return RegisterResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail =
          (e.response?.data is Map &&
              (e.response!.data as Map).containsKey('detail'))
          ? e.response!.data['detail']?.toString()
          : null;
      throw Exception(detail ?? 'Gagal daftar. Coba lagi');
    }
  }

  Future<UpdateMeResponse> updateMe(UpdateMeRequest req) async {
    final res = await _dio.put(ApiPaths.updateMe, data: req.toJson());
    return UpdateMeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // (opsional) watchlist
  Future<List<dynamic>> myWatchlist() async {
    final res = await _dio.get(ApiPaths.myWatchlist);
    // return res.data
    //     as List<dynamic>; // bisa bikin model StockListItem kalau mau
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(StockListItem.fromJson).toList();
  }

  Future<void> addWatchlist(String ticker) async {
    await _dio.post(ApiPaths.myWatchlist, data: {"ticker": ticker});
  }

  Future<void> deleteWatchlist(String ticker) async {
    await _dio.delete(ApiPaths.deleteWatch(ticker));
  }

  Future<CheckAccountResponse> checkAccount({
    required String email,
    required String phoneE164,
  }) async {
    try {
      final res = await _dio.post(
        ApiPaths.authCheck,
        data: {'email': email.trim().toLowerCase(), 'phone': phoneE164},
      );
      return CheckAccountResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map &&
              (e.response!.data as Map).containsKey('detail'))
          ? e.response!.data['detail']?.toString()
          : 'Gagal memeriksa akun';
      throw Exception(msg);
    }
  }
}

class OtpChallenge {
  final String challengeId;
  final int expiresIn;
  final String? codeDev;
  OtpChallenge(this.challengeId, this.expiresIn, this.codeDev);
}

extension OtpEndpoints on AuthService {
  Future<OtpChallenge> requestOtp(String type) async {
    // Contoh: POST /auth/otp/request { "type": "email"|"whatsapp" }
    final res = await _dio.post('/auth/otp/request', data: {'type': type});
    final data = res.data as Map<String, dynamic>;
    return OtpChallenge(
      data['challenge_id'] as String,
      (data['expires_in'] as num).toInt(),
      data['code_dev'] as String?,
    );
  }

  Future<bool> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    // Contoh: POST /auth/otp/verify { "challenge_id": "...", "code": "123456" }
    // Balasan: TokenPairResponse (Access_token, Refresh_token, expires_in)
    final res = await _dio.post(
      '/auth/otp/verify',
      data: {'challenge_id': challengeId, 'code': code},
    );
    final tp = TokenPairResponse.fromJson(res.data);
    await _storage.saveTokens(access: tp.accessToken, refresh: tp.refreshToken);
    return true;
  }
}

class CheckAccountResponse {
  final bool emailExists;
  final bool phoneExists;
  CheckAccountResponse({required this.emailExists, required this.phoneExists});

  factory CheckAccountResponse.fromJson(Map<String, dynamic> json) {
    return CheckAccountResponse(
      emailExists: (json['email_exists'] as bool?) ?? false,
      phoneExists: (json['phone_exists'] as bool?) ?? false,
    );
  }
}
