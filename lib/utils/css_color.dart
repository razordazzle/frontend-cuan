import 'dart:ui';

/// Konversi [Color] ke string warna CSS untuk dikirim ke chart di WebView.
extension CssColor on Color {
  /// `#rrggbb` (tanpa alpha). Pakai hanya kalau JS memang butuh hex.
  String toCssHex() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// `rgba(r, g, b, a)`, alpha ikut terkirim.
  String toCssRgba() {
    final int argb = toARGB32();
    return 'rgba(${(argb >> 16) & 0xFF}, ${(argb >> 8) & 0xFF}, ${argb & 0xFF}, '
        '${a.toStringAsFixed(3)})';
  }
}
