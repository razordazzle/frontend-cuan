import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/checkout_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CheckoutService {
  final Dio _dio;
  CheckoutService(AuthInterceptor interceptor)
    : _dio = ApiClient.instance(interceptor);

  /// Isi [packageCode] untuk beli membership, atau [journalId] untuk unlock satu journal premium.
  Future<CheckoutResponse> checkout({
    String? packageCode,
    String? journalId,
    int validTime = 9000,
    bool reuseIfPending = true,
  }) async {
    final res = await _dio.post(
      '/checkout',
      data: {
        'item_type': journalId != null ? 'journal' : 'subscription',
        if (packageCode != null) 'package_code': packageCode,
        if (journalId != null) 'journal_id': journalId,
        'valid_time': validTime,
        'reuse_if_pending': reuseIfPending,
      },
      // Checkout nunggu gateway QRIS (backend kasih batas 15 detik). Default 20 detik terlalu
      // mepet: FE keburu timeout sebelum sempat nerima pesan error dari backend.
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    debugPrint('CHECKOUT RAW: ${res.data}');
    return CheckoutResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
