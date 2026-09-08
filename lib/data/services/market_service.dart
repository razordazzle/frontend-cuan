import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/model/market_item.dart';
import 'package:dio/dio.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/token_storage.dart';
class MarketService {
  final Dio _dio;
  MarketService(TokenStorage storage)
      : _dio = ApiClient.instance(
          AuthInterceptor(storage: storage, onRefresh: (t) async => null),
        );

  Future<List<Map<String, dynamic>>> getMarket() async {
    final res = await _dio.get(ApiPaths.market);
    // Sesuaikan dengan schemas kamu (MarketItem / Market list response)
    // Misal backend return: {"items":[...]}
    final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
    return items;
  }

   Future<List<MarketItem>> top({
    required String metric, // 'gainers' | 'losers' | 'volume'
    int limit = 10,
  }) async {
    final res = await _dio.get(
      ApiPaths.marketTop,
      queryParameters: {'metric': metric, 'limit': limit},
    );
    final data = (res.data as List);
    return data.map((e) => MarketItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
