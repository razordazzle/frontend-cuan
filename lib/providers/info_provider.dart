import 'package:cuan_app/data/response/about_response.dart';
import 'package:cuan_app/data/response/faq_response.dart';
import 'package:cuan_app/data/services/info_service.dart';
import 'package:flutter/material.dart';

class InfoProvider extends ChangeNotifier {
  final InfoService _svc;
  InfoProvider(this._svc);

  // TERMS
  bool loadingTerms = false;
  String? termsMd;
  String? termsTitle;
  String? termsVersion;
  String? termsError;

  // PRIVACY (Tambahan Baru)
  bool loadingPrivacy = false;
  String? privacyMd;
  String? privacyTitle;
  String? privacyVersion;
  String? privacyError;

  // FAQ
  bool loadingFaq = false;
  FaqResponse? faq;
  String? faqError;

  // ABOUT
  bool loadingAbout = false;
  AboutResponse? about;
  String? aboutError;

  Future<void> fetchTerms({bool force = false}) async {
    if (termsMd != null && !force) return;
    loadingTerms = true;
    termsError = null;
    notifyListeners();
    try {
      final data = await _svc.getTerms();
      // Ekstrak sesuai nama kolom di database (models.py)
      termsMd = data['content_md'];
      termsTitle = data['title'];
      termsVersion = data['version'];
    } catch (_) {
      termsError = 'Gagal memuat Syarat & Ketentuan';
    } finally {
      loadingTerms = false;
      notifyListeners();
    }
  }

  // Future<void> fetchPrivacy({bool force = false}) async {
  //   if (privacyMd != null && !force) return;
  //   loadingPrivacy = true;
  //   privacyError = null;
  //   notifyListeners();
  //   try {
  //     final data = await _svc.getPrivacy();
  //     privacyMd = data['content_md'];
  //     privacyTitle = data['title'];
  //     privacyVersion = data['version'];
  //   } catch (_) {
  //     privacyError = 'Gagal memuat Kebijakan Privasi';
  //   } finally {
  //     loadingPrivacy = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchFaq({bool force = false}) async {
    if (faq != null && !force) return;
    loadingFaq = true;
    faqError = null;
    notifyListeners();
    try {
      faq = FaqResponse.fromJson(await _svc.getFaq());
    } catch (_) {
      faqError = 'Gagal memuat FAQ';
    } finally {
      loadingFaq = false;
      notifyListeners();
    }
  }

  Future<void> fetchAbout({bool force = false}) async {
    if (about != null && !force) return;
    loadingAbout = true;
    aboutError = null;
    notifyListeners();
    try {
      about = AboutResponse.fromJson(await _svc.getAbout());
    } catch (_) {
      aboutError = 'Gagal memuat info aplikasi';
    } finally {
      loadingAbout = false;
      notifyListeners();
    }
  }
}
