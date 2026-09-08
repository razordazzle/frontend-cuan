import 'package:cuan_app/data/model/community_models.dart';
import 'package:cuan_app/data/services/community_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _svc;
  CommunityProvider(this._svc);

  bool loading = false;
  String? error;
  CommunityLinkResponse? link;

  Future<void> fetchLink() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      link = await _svc.getJoinLink();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> openLink(BuildContext context) async {
    // pastikan sudah ada link; kalau belum, fetch dulu
    if (link == null) {
      await fetchLink();
      if (link == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil tautan komunitas.')),
        );
        return;
      }
    }
    final uri = Uri.tryParse(link!.link);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan komunitas tidak valid.')),
      );
      return;
    }
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan komunitas.')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
