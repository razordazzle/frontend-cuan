/// Potong (bukan bulatkan) ke [decimals] angka di belakang koma, ke arah nol.
/// Contoh: 400.9166 -> 400.91 (bukan 400.92), -6.3489 -> -6.34.
/// Epsilon kecil menahan error float (mis. 0.29 * 100 = 28.999999…).
double truncateDecimals(num value, int decimals) {
  var factor = 1;
  for (var i = 0; i < decimals; i++) {
    factor *= 10;
  }
  final shifted = value * factor;
  final eps = value >= 0 ? 1e-9 : -1e-9;
  return (shifted + eps).truncate() / factor;
}
