// lib/data/services/search_service.dart
import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/search_models.dart';
import 'package:dio/dio.dart';

class SearchService {
  final Dio _dio;
  SearchService(AuthInterceptor interceptor)
      : _dio = ApiClient.instance(interceptor);

  Future<SearchResponse> search({
    required String q,
    String? type,     // contoh: 'stock|journal|playlist'
    int limit = 10,
  }) async {
    final res = await _dio.get(
      ApiPaths.search,
      queryParameters: {
        'q': q,
        if (type != null && type.isNotEmpty) 'type': type,
        'limit': limit,
      },
    );
    return SearchResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
