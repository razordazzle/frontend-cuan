import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:dio/dio.dart';

class InfoService {
  final Dio _dio;
  InfoService(AuthInterceptor interceptor)
    : _dio = ApiClient.instance(interceptor);

  /// Ambil Terms dalam bentuk JSON dari database
  Future<Map<String, dynamic>> getTerms() async {
    // Sesuaikan path endpoint dengan yang ada di FastAPI kamu
    final res = await _dio.get('/legal/terms'); 
    return res.data as Map<String, dynamic>;
  }
  // Future<Map<String, dynamic>> getPrivacy() async {
  //   final res = await _dio.get('/legal/privacy'); 
  //   return res.data as Map<String, dynamic>;
  // }

  Future<Map<String, dynamic>> getFaq() async {
    final res = await _dio.get('/help');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAbout() async {
    final res = await _dio.get('/about');
    return res.data as Map<String, dynamic>;
  }
}
