import 'package:dio/dio.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/model/journal_models.dart';

/// 402 Payment Required dari backend → lempar exception ini berisi preview & harga unlock
class JournalPaywalled implements Exception {
  final String preview;
  final int? priceIdr; // null = harga belum diatur admin (cuma bisa lewat membership)
  JournalPaywalled(this.preview, {this.priceIdr});
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
        // backend kirim: {"detail":{"is_premium":true,"preview":"...","price_idr":25000,
        //                           "cta":"purchase_or_subscribe"}}
        // (Dulu throw-nya di dalam try, jadi selalu ketangkep catch sendiri & preview asli hilang.)
        final data = e.response?.data;
        final detail = data is Map ? data['detail'] : null;
        if (detail is Map) {
          throw JournalPaywalled(
            detail['preview']?.toString() ?? '',
            priceIdr: (detail['price_idr'] as num?)?.toInt(),
          );
        }
        throw JournalPaywalled('Konten premium. Silakan berlangganan.');
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
