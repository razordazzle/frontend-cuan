import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/token_storage.dart';
import 'package:cuan_app/data/response/me_response.dart';
import 'package:dio/dio.dart';

class UsersService {
  final Dio _dio;
  UsersService._(this._dio);

  factory UsersService.fromStorage(TokenStorage storage) {
    final interceptor = AuthInterceptor(
      storage: storage,
      onRefresh: (refreshToken) async {
        try {
          final dio = Dio(ApiClient.instance(AuthInterceptor(storage: TokenStorage(), onRefresh: (_) async => null)).options);
          final res = await dio.post('/auth/refresh', data: {'Refresh_token': refreshToken});
          final access = res.data['Access_token'] as String;
          await storage.saveTokens(access: access, refresh: refreshToken);
          return access;
        } catch (_) {
          await storage.clear();
          return null;
        }
      },
    );
    final dio = ApiClient.instance(interceptor);
    return UsersService._(dio);
  }

  Future<MeResponse> me() async {
    final res = await _dio.get('/users/me');
    return MeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateMe({
    String? name,
    String? username,
    String? birthPlace,
    String? birthDate, // YYYY-MM-DD
    String? domicile,
    String? phone,
  }) async {
    await _dio.put('/users/me', data: {
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (birthPlace != null) 'birth_place': birthPlace,
      if (birthDate != null) 'birth_date': birthDate,
      if (domicile != null) 'domicile': domicile,
      if (phone != null) 'phone': phone,
    });
  }
}