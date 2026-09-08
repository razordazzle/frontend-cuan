import 'dart:async';

import 'package:cuan_app/data/model/search_models.dart';
import 'package:cuan_app/data/services/search_service.dart';
import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _svc;
  SearchProvider(this._svc);

  bool loading = false;
  String? error;
  List<SearchResultItem> results = [];

  Timer? _deb;
  void search(String q, {String? type, int limit = 10}) {
    _deb?.cancel();
    // debounce ringan
    _deb = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().isEmpty) {
        results = [];
        error = null;
        notifyListeners();
        return;
      }
      loading = true;
      error = null;
      notifyListeners();
      try {
        final r = await _svc.search(q: q.trim(), type: type, limit: limit);
        results = r.results;
      } catch (e) {
        error = e.toString();
      } finally {
        loading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _deb?.cancel();
    super.dispose();
  }
}
