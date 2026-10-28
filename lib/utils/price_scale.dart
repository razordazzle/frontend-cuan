import 'dart:math' as math;

/// Fraksi harga (1 tik) saham berdasarkan harga. Batas atas inklusif:
/// harga 200 masih 1 poin, tapi tik berikutnya sudah 202 (2 poin).
double priceTickSize(double price) {
  if (price <= 200) return 1;
  if (price <= 500) return 2;
  if (price <= 2000) return 5;
  if (price <= 5000) return 10;
  return 25;
}

/// Interval garis/label sumbu harga untuk chart emiten.
///
/// Selalu bilangan bulat dan kelipatan fraksi harga, jadi tidak ada label berkoma dan setiap label
/// adalah harga yang valid. Rentang tampil sempit (intraday) tetap dapat label rapat: minimal 1 tik.
/// [targetTicks] = perkiraan jumlah garis yang diinginkan.
double priceAxisInterval(
  double rawMin,
  double rawMax, {
  int targetTicks = 8,
}) {
  final tick = priceTickSize(rawMax);
  final rough = (rawMax - rawMin) / targetTicks;
  final needed = math.max(rough, tick);

  // Angka "cantik" (1, 2, 2.5, 5 x 10^n) terkecil yang >= kebutuhan, bulat, dan kelipatan tik.
  for (var exp = 0; exp < 12; exp++) {
    final mag = math.pow(10, exp).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0]) {
      final n = m * mag;
      if (n >= needed && n == n.roundToDouble() && n % tick == 0) return n;
    }
  }
  return (needed / tick).ceil() * tick;
}
