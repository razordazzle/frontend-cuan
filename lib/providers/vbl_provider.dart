// lib/providers/vbl_provider.dart
import 'package:flutter/material.dart';
import 'package:cuan_app/data/services/vbl_service.dart';
import 'package:cuan_app/data/model/vbl_models.dart';

class VblProvider extends ChangeNotifier {
  final VblService _svc;
  VblProvider(this._svc);

  // VblService get svc => _svc;
  /* ========= PLAYLIST LIST ========= */
  bool loadingList = false;
  String? errList;
  List<VblPlaylistItem>?
  playlists; // nullable biar gampang cek "belum pernah load"
  String? nextCursor;
  VblProgressLatestResponse? videoProgress;
  VblPlaylistProgress? playlistProgressData;

  Future<void> fetchPlaylists({
    String? category,
    String? level,
    String? search,
    int limit = 20,
  }) async {
    loadingList = true;
    errList = null;
    notifyListeners();
    try {
      final r = await _svc.listPlaylists(
        category: category,
        level: level,
        search: search,
        limit: limit,
      );
      playlists = r.items;
      nextCursor = r.nextCursor;
    } catch (e) {
      errList = 'Gagal memuat playlist';
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  /* ========= PLAYLIST DETAIL (DAFTAR VIDEO) ========= */
  bool loadingDetail = false;
  String? errDetail;
  VblPlaylistDetailResponse? detail;

  Future<void> fetchDetail(String playlistId) async {
    loadingDetail = true;
    errDetail = null;
    notifyListeners();
    try {
      detail = await _svc.playlistDetail(playlistId);
    } catch (e) {
      errDetail = 'Gagal memuat detail playlist';
    } finally {
      loadingDetail = false;
      notifyListeners();
    }
  }

  /* ========= VIDEO DETAIL (URL/DESKRIPSI) ========= */
  bool loadingVideo = false;
  String? errVideo;
  VblVideoDetailResponse? video;

  Future<void> fetchVideo(String videoId) async {
    loadingVideo = true;
    errVideo = null;
    notifyListeners();
    try {
      video = await _svc.videoDetail(videoId);
    } catch (e) {
      errVideo = 'Gagal memuat video';
    } finally {
      loadingVideo = false;
      notifyListeners();
    }
  }

  /* ========= LATEST PROGRESS ========= */
  VblProgressLatestResponse? latest;

  Future<void> fetchLatestProgress() async {
    try {
      latest = await _svc.latestProgress();
      notifyListeners();
    } catch (_) {
      // diamkan saja; belum ada progres = bukan error fatal
    }
  }

  /* ========= SAVE PROGRESS ========= */
  Future<void> saveProgress({
    required String playlistId,
    required String videoId,
    required double progressPct, // ⬅ nama disamakan dengan pemanggil
    required bool isCompleted, // ⬅ nama disamakan dengan pemanggil
  }) async {
    await _svc.saveProgress(
      playlistId: playlistId,
      videoId: videoId,
      progressPct: progressPct,
      isCompleted: isCompleted,
    );
    // opsional: refresh latest agar UI up-to-date
    try {
      latest = await _svc.latestProgress();
      notifyListeners();
    } catch (_) {}
  }

  /* ========= HISTORY ========= */
  bool loadingHistory = false;
  String? errHistory;
  final List<VblHistoryItem> histories = [];
  String? historyCursor;
  bool historyExhausted = false;

  Future<void> fetchHistory({int limit = 50, bool refresh = false}) async {
    if (loadingHistory) return;
    loadingHistory = true;
    errHistory = null;
    if (refresh) {
      histories.clear();
      historyCursor = null;
      historyExhausted = false;
    }
    notifyListeners();

    try {
      final res = await _svc.listHistory(limit: limit, cursor: historyCursor);

      if (refresh) histories.clear();
      histories.addAll(res.items);
      historyCursor = res.nextCursor;
      historyExhausted = res.nextCursor == null || res.items.isEmpty;
    } catch (e) {
      errHistory = 'Gagal memuat riwayat video';
    } finally {
      loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory({int limit = 50}) async {
    if (historyExhausted || loadingHistory) return;
    await fetchHistory(limit: limit);
  }

  Future<VblProgressLatestResponse?> fetchProgressForVideo(
    String videoId,
  ) async {
    try {
      videoProgress = await _svc.progressForVideo(videoId);
      return videoProgress;
    } catch (_) {
      videoProgress = null;
      return null; // belum pernah ditonton, itu normal
    }
  }

  Future<void> fetchPlaylistProgress(String playlistId) async {
    try {
      playlistProgressData = await _svc.playlistProgress(playlistId);
      notifyListeners();
    } catch (_) {
      playlistProgressData = null;
    }
  }
}
