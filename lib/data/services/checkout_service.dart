import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/checkout_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CheckoutService {
  final Dio _dio;
  CheckoutService(AuthInterceptor interceptor)
    : _dio = ApiClient.instance(interceptor);

  Future<CheckoutResponse> checkout({
    required String packageCode, // DAY/MONTH/YEAR
    int validTime = 9000,
    bool reuseIfPending = true,
  }) async {
    final res = await _dio.post(
      '/checkout',
      data: {
        'package_code': packageCode,
        'valid_time': validTime,
        'reuse_if_pending': reuseIfPending,
      },
    );
    debugPrint('CHECKOUT RAW: ${res.data}');
    return CheckoutResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
