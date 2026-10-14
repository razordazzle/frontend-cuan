import 'dart:async';

import 'package:cuan_app/data/model/checkout_response.dart';
import 'package:cuan_app/data/services/checkout_service.dart';
import 'package:cuan_app/data/services/qris_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class QrisProvider extends ChangeNotifier {
  final CheckoutService _checkout;
  final QrisService _qris;

  QrisProvider(this._checkout, this._qris);

  bool loading = false;
  String? error;

  CheckoutResponse? current;
  String statusText = 'Menunggu pembayaran...';
  bool paid = false;
  bool expired = false;

  Timer? _pollTimer;

  /// Isi [packageCode] untuk beli membership, atau [journalId] untuk unlock satu journal premium.
  Future<void> startCheckout({
    String? packageCode,
    String? journalId,
    int validTime = 9000,
    bool reuseIfPending = true,
  }) async {
    // Bersihkan sisa checkout sebelumnya: kalau checkout ini gagal, halaman detail
    // jangan sampai nampilin QR / invoice lama.
    await stopPolling();
    current = null;
    loading = true;
    error = null;
    paid = false;
    expired = false;
    statusText = 'Menyiapkan pembayaran...';
    notifyListeners();

    try {
      current = await _checkout.checkout(
        packageCode: packageCode,
        journalId: journalId,
        validTime: validTime,
        reuseIfPending: reuseIfPending,
      );
      debugPrint(
        'CHECKOUT: invoice=${current?.invoiceId} ref=${current?.partnerRefNo}',
      );
      loading = false;
      statusText = 'Scan QR untuk bayar';
      notifyListeners();

      _startPolling();
    } catch (e) {
      loading = false;
      error = _checkoutErrorMessage(e);
      statusText = 'Gagal';
      notifyListeners();
    }
  }

  // Pesan yang bisa dibaca user: pakai `detail` dari backend kalau ada,
  // bukan teks mentah DioException.
  String _checkoutErrorMessage(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Server terlalu lama merespons. Silakan coba lagi.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
      }
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    }
    return 'Gagal memulai checkout. Silakan coba lagi.';
  }

  void _startPolling() {
    _pollTimer?.cancel();
    final ref = current?.partnerRefNo;
    if (ref == null || ref.isEmpty) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      try {
        final r = await _qris.query(partnerRefNo: ref);

        if (r.isPaid) {
          paid = true;
          statusText = 'Pembayaran berhasil';
          notifyListeners();
          t.cancel();
        } else if (r.isExpired) {
          // Invoice lewat batas waktu: berhenti polling, user harus checkout ulang
          expired = true;
          statusText = r.statusText;
          notifyListeners();
          t.cancel();
        } else {
          statusText = r.statusText;
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  Future<void> refreshOnce() async {
    final ref = current?.partnerRefNo;
    if (ref == null || ref.isEmpty) return;
    try {
      final r = await _qris.query(partnerRefNo: ref);
      if (r.isPaid) {
        paid = true;
        statusText = 'Pembayaran berhasil';
      } else if (r.isExpired) {
        expired = true;
        statusText = r.statusText;
        await stopPolling();
      } else {
        statusText = r.statusText;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> stopPolling() async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
