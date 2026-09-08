// lib/data/model/vbl_models.dart
class VblPlaylistItem {
  final String playlistId, title, category, level, thumbnail;
  final int totalVideos;
  final int durationSec;           // server kirim dalam detik
  final String durationHuman;      // “1h20m”
  VblPlaylistItem({
    required this.playlistId,
    required this.title,
    required this.category,
    required this.level,
    required this.thumbnail,
    required this.totalVideos,
    required this.durationSec,
    required this.durationHuman,
  });
  factory VblPlaylistItem.fromJson(Map<String, dynamic> j) => VblPlaylistItem(
    playlistId: j['playlist_id'],
    title: j['title'] ?? '',
    category: j['category'] ?? '',
    level: j['level'] ?? '',
    thumbnail: j['thumbnail'] ?? '',
    totalVideos: (j['total_videos'] as num?)?.toInt() ?? 0,
    durationSec: (j['duration_sec'] as num?)?.toInt() ?? 0,
    durationHuman: j['duration_human'] ?? '',
  );
}

class VblPlaylistListResponse {
  final List<VblPlaylistItem> items;
  final String? nextCursor;
  VblPlaylistListResponse({required this.items, this.nextCursor});
  factory VblPlaylistListResponse.fromJson(Map<String, dynamic> j) =>
      VblPlaylistListResponse(
        items: (j['items'] as List).map((e) => VblPlaylistItem.fromJson(e)).toList(),
        nextCursor: j['next_cursor'] as String?,
      );
}

class VblPlaylistVideoItem {
  final String videoId, title;
  final int duration, sequence;
  VblPlaylistVideoItem({required this.videoId, required this.title, required this.duration, required this.sequence});
  factory VblPlaylistVideoItem.fromJson(Map<String, dynamic> j) => VblPlaylistVideoItem(
    videoId: j['video_id'],
    title: j['title'] ?? '',
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    sequence: (j['sequence'] as num?)?.toInt() ?? 0,
  );
}

class VblPlaylistDetailResponse {
  final String playlistId, title, description;
  final List<VblPlaylistVideoItem> videos;
  VblPlaylistDetailResponse({required this.playlistId, required this.title, required this.description, required this.videos});
  factory VblPlaylistDetailResponse.fromJson(Map<String, dynamic> j) =>
      VblPlaylistDetailResponse(
        playlistId: j['playlist_id'],
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        videos: (j['videos'] as List).map((e) => VblPlaylistVideoItem.fromJson(e)).toList(),
      );
}

class VblVideoDetailResponse {
  final String videoUrl, description;
  VblVideoDetailResponse({required this.videoUrl, required this.description});
  factory VblVideoDetailResponse.fromJson(Map<String, dynamic> j) =>
      VblVideoDetailResponse(videoUrl: j['video_url'] ?? '', description: j['description'] ?? '');
}

class VblProgressLatestResponse {
  final String playlistId, playlistTitle, videoId, videoTitle;
  final double progressPct;
  final bool isCompleted;
  VblProgressLatestResponse({
    required this.playlistId,
    required this.playlistTitle,
    required this.videoId,
    required this.videoTitle,
    required this.progressPct,
    required this.isCompleted,
  });
  factory VblProgressLatestResponse.fromJson(Map<String, dynamic> j) =>
      VblProgressLatestResponse(
        playlistId: j['playlist_id'],
        playlistTitle: j['playlist_title'] ?? '',
        videoId: j['video_id'],
        videoTitle: j['video_title'] ?? '',
        progressPct: (j['progress_pct'] as num?)?.toDouble() ?? 0,
        isCompleted: j['is_completed'] == true,
      );
}

class VblHistoryItem {
  final String playlistId;
  final String playlistTitle;
  final String? thumbnail;
  final String videoId;
  final String videoTitle;
  final int sequence;
  final int duration;      // detik
  final double progressPct;
  final bool isCompleted;
  final DateTime updatedAt;

  VblHistoryItem({
    required this.playlistId,
    required this.playlistTitle,
    required this.thumbnail,
    required this.videoId,
    required this.videoTitle,
    required this.sequence,
    required this.duration,
    required this.progressPct,
    required this.isCompleted,
    required this.updatedAt,
  });

  factory VblHistoryItem.fromJson(Map<String, dynamic> j) => VblHistoryItem(
        playlistId: j['playlist_id'],
        playlistTitle: j['playlist_title'],
        thumbnail: j['thumbnail'],
        videoId: j['video_id'],
        videoTitle: j['video_title'],
        sequence: (j['sequence'] ?? 0) as int,
        duration: (j['duration'] ?? 0) as int,
        progressPct: (j['progress_pct'] ?? 0).toDouble(),
        isCompleted: j['is_completed'] == true,
        updatedAt: DateTime.parse(j['updated_at']),
      );
}

class VblHistoryListResponse {
  final List<VblHistoryItem> items;
  final String? nextCursor;
  VblHistoryListResponse({required this.items, required this.nextCursor});

  factory VblHistoryListResponse.fromJson(Map<String, dynamic> j) =>
      VblHistoryListResponse(
        items: (j['items'] as List<dynamic>)
            .map((e) => VblHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: j['next_cursor'],
      );
}