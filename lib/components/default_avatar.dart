import 'package:flutter/material.dart';

/// Foto profil bawaan: lingkaran abu-abu dengan siluet kepala dan bahu berwarna putih.
///
/// Digambar dengan vektor (bukan gambar jaringan/aset), jadi tajam di ukuran berapa pun dan tidak
/// bergantung pada koneksi. Proporsi diukur dari gambar referensi desain.
class DefaultAvatar extends StatelessWidget {
  /// Jari-jari lingkaran (sama artinya dengan `CircleAvatar.radius`).
  final double radius;

  /// Warna lingkaran (bawaan abu-abu terang sesuai referensi).
  final Color background;

  /// Warna siluet kepala dan bahu.
  final Color foreground;

  const DefaultAvatar({
    super.key,
    this.radius = 36,
    this.background = const Color(0xFFDDE1E2),
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: CustomPaint(
          painter: _DefaultAvatarPainter(
            background: background,
            foreground: foreground,
          ),
        ),
      ),
    );
  }
}

class _DefaultAvatarPainter extends CustomPainter {
  final Color background;
  final Color foreground;
  const _DefaultAvatarPainter({
    required this.background,
    required this.foreground,
  });

  // Proporsi terhadap jari-jari lingkaran (R). Titik tengah lingkaran = (0, 0), sumbu y ke bawah.
  static const double _headCy = -0.243; // pusat kepala di atas tengah
  static const double _headR = 0.327;
  static const double _shoulderCy = 0.783; // pusat kubah bahu di bawah tengah
  static const double _shoulderRx = 0.683;
  static const double _shoulderRy = 0.593;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(c, r, Paint()..color = background);

    final fg = Paint()..color = foreground;
    canvas.drawCircle(c + Offset(0, _headCy * r), _headR * r, fg);
    // Bahu: separuh elips yang terpotong tepi lingkaran (ClipOval di widget)
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, _shoulderCy * r),
        width: _shoulderRx * r * 2,
        height: _shoulderRy * r * 2,
      ),
      fg,
    );
  }

  @override
  bool shouldRepaint(_DefaultAvatarPainter old) =>
      old.background != background || old.foreground != foreground;
}
