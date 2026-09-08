import 'package:flutter/material.dart';
import 'package:cuan_app/data/services/journals_service.dart';
import 'package:cuan_app/data/model/journal_models.dart';

class JournalsProvider extends ChangeNotifier {
  final JournalsService _svc;
  JournalsProvider(this._svc);

  // LIST
  bool loadingList = false;
  String? errList;
  List<JournalListItem>? items;
  String? nextCursor;

  Future<void> fetchList({
    String filter = 'all',
    String sort = 'latest',
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    loadingList = true;
    errList = null;
    notifyListeners();
    try {
      final r = await _svc.list(
        filter: filter,
        sort: sort,
        search: search,
        limit: limit,
        cursor: cursor,
      );
      items = r.items;
      nextCursor = r.nextCursor;
    } catch (e) {
      errList = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  // DETAIL
  bool loadingDetail = false;
  String? errDetail;
  JournalDetailResponse? detail;
  String? preview; // terisi kalau paywalled

  Future<void> fetchDetail(String id) async {
    loadingDetail = true;
    errDetail = null;
    preview = null;
    detail = null;
    notifyListeners();
    try {
      detail = await _svc.detail(id);
    } on JournalPaywalled catch (e) {
      preview = e.preview;
    } catch (e) {
      errDetail = e.toString();
    } finally {
      loadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> hasAccess(String id) async {
    try {
      final r = await _svc.access(id);
      return r.hasAccess;
    } catch (_) {
      return false;
    }
  }

  Future<JournalDetailResponse> fetchDetailOnce(String id) {
    // tidak mengubah state provider; langsung return dari service
    return _svc.detail(id);
  }

  Future<JournalPreviewResponse> fetchPreview(String id) {
    // tidak mengubah state provider; langsung return dari service
    return _svc.preview(id);
  }
}
