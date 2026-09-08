import 'package:flutter/foundation.dart';

/// Kelompok metode untuk membedakan layout di halaman detail.
enum PaymentGroup { virtualAccount, bankTransfer, ewallet, qris }

@immutable
class PaymentMethod {
  final String id;         // unique key, mis. "bca_va", "qris"
  final String label;      // text ditampilkan, mis. "BCA", "QRIS"
  final String logoAsset;  // path asset logo
  final PaymentGroup group;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.logoAsset,
    required this.group,
  });

  bool get isQris => group == PaymentGroup.qris;

  // --- Preset contoh (optional, bisa kamu hapus/ganti dari API) ---
  static const qris = PaymentMethod(
    id: 'qris',
    label: 'QRIS',
    logoAsset: 'assets/payments/qris.png',
    group: PaymentGroup.qris,
  );

  static const bcaVA = PaymentMethod(
    id: 'bca_va',
    label: 'BCA',
    logoAsset: 'assets/payments/bca.png',
    group: PaymentGroup.virtualAccount,
  );

  static const bcaTransfer = PaymentMethod(
    id: 'bca',
    label: 'BCA',
    logoAsset: 'assets/payments/bca.png',
    group: PaymentGroup.bankTransfer,
  );

  static const mandiri = PaymentMethod(
    id: 'mandiri',
    label: 'MANDIRI',
    logoAsset: 'assets/payments/mandiri.png',
    group: PaymentGroup.bankTransfer,
  );

  static const dana = PaymentMethod(
    id: 'dana',
    label: 'DANA',
    logoAsset: 'assets/payments/dana.png',
    group: PaymentGroup.ewallet,
  );

  static const ovo = PaymentMethod(
    id: 'ovo',
    label: 'OVO',
    logoAsset: 'assets/payments/ovo.png',
    group: PaymentGroup.ewallet,
  );

  static const gopay = PaymentMethod(
    id: 'gopay',
    label: 'GOPAY',
    logoAsset: 'assets/payments/gopay.png',
    group: PaymentGroup.ewallet,
  );

  static const presets = <PaymentMethod>[
    qris, bcaVA, bcaTransfer, mandiri, dana, ovo, gopay,
  ];
}
