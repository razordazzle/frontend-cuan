import 'package:dio/dio.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/model/journal_models.dart';

/// 402 Payment Required dari backend → lempar exception ini berisi preview
class JournalPaywalled implements Exception {
  final String preview;
  JournalPaywalled(this.preview);
  @override
  String toString() => 'PAYWALLED: $preview';
}

class JournalsService {
  final Dio _dio;
  JournalsService(AuthInterceptor itc) : _dio = ApiClient.instance(itc);

  Future<JournalListResponse> list({
    String filter = 'all', // all|research|knowledge
    String sort = 'latest', // latest|oldest
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    final res = await _dio.get(
      ApiPaths.journals,
      queryParameters: {
        'filter': filter,
        'sort': sort,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return JournalListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<JournalDetailResponse> detail(String journalId) async {
    try {
      final res = await _dio.get(ApiPaths.journalDetail(journalId));
      return JournalDetailResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 402) {
        // backend kirim: {"detail":{"is_premium":true,"preview":"...","cta":"subscribe"}}
        final data = e.response?.data;
        try {
          final preview = (data?['detail']?['preview'] ?? '') as String;
          throw JournalPaywalled(preview);
        } catch (_) {
          throw JournalPaywalled('Konten premium. Silakan berlangganan.');
        }
      }
      rethrow;
    }
  }

  Future<JournalPreviewResponse> preview(String journalId) async {
    final res = await _dio.get(ApiPaths.journalPreview(journalId));
    return JournalPreviewResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<JournalAccessResponse> access(String journalId) async {
    final res = await _dio.get(ApiPaths.journalAccess(journalId));
    return JournalAccessResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
