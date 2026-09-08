import 'package:cuan_app/config/app_config.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

  static Dio instance(AuthInterceptor interceptor) {
    if (!_dio.interceptors.contains(interceptor)) {
      _dio.interceptors.add(interceptor);
      interceptor.attach(_dio); // <-- ini kunci
    }
    return _dio;
  }
}