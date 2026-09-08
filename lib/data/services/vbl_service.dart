// lib/data/services/vbl_service.dart
import 'package:dio/dio.dart';
import 'package:cuan_app/config/api_paths.dart';
import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/vbl_models.dart';

class VblService {
  final Dio _dio;
  VblService(AuthInterceptor interceptor)
    : _dio = ApiClient.instance(interceptor);

  Future<VblPlaylistListResponse> listPlaylists({
    String? category,
    String? level,
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    final res = await _dio.get(
      ApiPaths.vblPlaylists, // '/vbl/playlists'
      queryParameters: {
        if (category?.isNotEmpty == true) 'category': category,
        if (level?.isNotEmpty == true) 'level': level,
        if (search?.isNotEmpty == true) 'search': search,
        'limit': limit,
        if (cursor?.isNotEmpty == true) 'cursor': cursor,
      },
    );
    return VblPlaylistListResponse.fromJson(res.data);
  }

  Future<VblPlaylistDetailResponse> playlistDetail(String playlistId) async {
    final res = await _dio.get('${ApiPaths.vblPlaylists}/$playlistId');
    return VblPlaylistDetailResponse.fromJson(res.data);
  }

  Future<VblVideoDetailResponse> videoDetail(String videoId) async {
    final res = await _dio.get(
      '${ApiPaths.vblVideos}/$videoId',
    ); // '/vbl/videos/{id}'
    return VblVideoDetailResponse.fromJson(res.data);
  }

  Future<bool> saveProgress({
    required String playlistId,
    required String videoId,
    required double progressPct,
    required bool isCompleted,
  }) async {
    await _dio.post(
      ApiPaths.vblProgress,
      data: {
        'playlist_id': playlistId,
        'video_id': videoId,
        'progress_pct': progressPct,
        'is_completed': isCompleted,
      },
    );
    return true;
  }

  Future<VblProgressLatestResponse> latestProgress() async {
    final res = await _dio.get('${ApiPaths.vblProgress}/latest');
    return VblProgressLatestResponse.fromJson(res.data);
  }

  Future<VblHistoryListResponse> listHistory({
    int limit = 50,
    String? cursor,
  }) async {
    final res = await _dio.get(
      '${ApiPaths.vblProgress}/history',
      queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
    );
    return VblHistoryListResponse.fromJson(res.data);
  }
}
