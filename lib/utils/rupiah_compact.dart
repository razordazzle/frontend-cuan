/// Rupiah ringkas untuk nilai besar: 206535361000 -> "Rp 206,5 M".
///
/// Satuan: Rb (ribu), Jt (juta), M (miliar), T (triliun). Pemisah desimal koma (format Indonesia).
/// [withSign] menambah "+" untuk nilai positif; nilai negatif selalu diawali "-".
String formatRupiahCompact(num? value, {bool withSign = false}) {
  if (value == null) return '-';
  final neg = value < 0;
  final abs = value.abs().toDouble();

  const units = <(double, String)>[
    (1e12, 'T'),
    (1e9, 'M'),
    (1e6, 'Jt'),
    (1e3, 'Rb'),
  ];

  String body = 'Rp ${abs.round()}';
  for (var i = 0; i < units.length; i++) {
    final (div, label) = units[i];
    if (abs < div) continue;
    var scaled = abs / div;
    // 999,96 M dibulatkan ke 1 desimal = 1000,0 -> naikkan ke satuan di atasnya (1,0 T)
    if (double.parse(scaled.toStringAsFixed(1)) >= 1000 && i > 0) {
      scaled = abs / units[i - 1].$1;
      body = 'Rp ${_dec(scaled)} ${units[i - 1].$2}';
    } else {
      body = 'Rp ${_dec(scaled)} $label';
    }
    break;
  }

  final isZero = body == 'Rp 0';
  if (neg && !isZero) return '-$body';
  if (withSign && !isZero) return '+$body';
  return body;
}

/// Satu desimal, tanpa ",0" di ujung; koma sebagai pemisah desimal.
String _dec(double v) {
  final s = v.toStringAsFixed(1);
  final trimmed = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  return trimmed.replaceFirst('.', ',');
}
