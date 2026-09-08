
import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/community_models.dart';
import 'package:dio/dio.dart';

class CommunityService {
  final Dio _dio;
  CommunityService(AuthInterceptor interceptor)
      : _dio = ApiClient.instance(interceptor);

  Future<CommunityLinkResponse> getJoinLink() async {
    final res = await _dio.get(ApiPaths.communityLink);
    return CommunityLinkResponse.fromJson(res.data as Map<String, dynamic>);
  }
}