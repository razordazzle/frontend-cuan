import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/qris_query_response.dart';
import 'package:dio/dio.dart';

class QrisService {
  final Dio _dio;
  QrisService(AuthInterceptor interceptor) : _dio = ApiClient.instance(interceptor);

  // Future<QrisGenerateResponse> generate({
  //   required String invoiceId,
  //   int validTime = 9000,
  //   bool reuseIfPending = true,
  // }) async {
  //   final res = await _dio.post(
  //     '/qris/generate',
  //     data: {
  //       'invoice_id': invoiceId,
  //       'valid_time': validTime,
  //       'reuse_if_pending': reuseIfPending,
  //     },
  //   );
  //   return QrisGenerateResponse.fromJson(res.data as Map<String, dynamic>);
  // }
  
  Future<QrisQueryResponse> query({required String partnerRefNo}) async {
    final res = await _dio.post(
      '/qris/query',
      data: {'partner_ref_no': partnerRefNo},
    );
    return QrisQueryResponse.fromJson(res.data as Map<String, dynamic>);
  }
}