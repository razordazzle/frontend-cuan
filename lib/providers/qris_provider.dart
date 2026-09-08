import 'dart:async';

import 'package:cuan_app/data/model/checkout_response.dart';
import 'package:cuan_app/data/model/qris_generate_response.dart';
import 'package:cuan_app/data/services/checkout_service.dart';
import 'package:cuan_app/data/services/qris_service.dart';
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

  Timer? _pollTimer;

  Future<void> startCheckout({
    required String packageCode, // DAY/MONTH/YEAR
    int validTime = 9000,
    bool reuseIfPending = true,
  }) async {
    loading = true;
    error = null;
    paid = false;
    statusText = 'Menyiapkan pembayaran...';
    notifyListeners();

    try {
      current = await _checkout.checkout(
        packageCode: packageCode,
        validTime: validTime,
        reuseIfPending: reuseIfPending,
      );
      print(
        'CHECKOUT: invoice=${current?.invoiceId} ref=${current?.partnerRefNo}',
      );
      print('QR LEN: ${current?.qrContent.length}');
      loading = false;
      statusText = 'Scan QR untuk bayar';
      notifyListeners();

      _startPolling();
    } catch (e) {
      loading = false;
      error = 'Gagal memulai checkout: ${e.toString()}';
      statusText = 'Gagal';
      notifyListeners();
    }
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
