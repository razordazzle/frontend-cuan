import 'package:cuan_app/components/gradient_border_button.dart';
import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/components/gradient_text.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:flutter/material.dart';

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  /// Gradien teks “Cuan App”: kiri terang → kanan gelap (pp lebih gelap)
  static const cuanGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF94F0F9), // terang (kiri)
      Color(0xFF00A3A8), // medium
      Color(0xFF006E72), // paling gelap (kanan)
    ],
    stops: [0.0, 0.58, 1.0],
  );

  /// Tombol Login (teal)
  static const loginGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00A3A8), Color(0xFF006E72)],
  );

  /// Border gradien untuk tombol Daftar
  static const daftarBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A9B8), Color(0xFF263238)], // blueGrey 900
  );

  /// Background tombol Daftar untuk LIGHT
  static const daftarBgLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF3F3F3)],
  );

  /// Background tombol Daftar untuk DARK
  static const daftarBgDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    final welcomeStyle = tt.titleLarge?.copyWith(
      color: cs.onBackground.withValues(alpha: 0.95),
      fontWeight: FontWeight.w600,
    );

    final cuanAppStyle =
        (tt.headlineMedium ??
                const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))
            .copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.35),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      "assets/splash/logo.png",
                      height: 120,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                    ),
                    const SizedBox(height: 36),

                    Text(
                      "Selamat datang di",
                      textAlign: TextAlign.center,
                      style: welcomeStyle,
                    ),
                    const SizedBox(height: 6),

                    GradientText(
                      "Cuan App",
                      gradient: cuanGradient,
                      style: cuanAppStyle,
                    ),

                    const SizedBox(height: 44),

                    // LOGIN: gradien teal
                    GradientButton(
                      label: "Login",
                      gradient: loginGradient,
                      textStyle: tt.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20, // 20–22 nyaman untuk tinggi 52
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      height: 52,
                      radius: 28,
                      shadow: true,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(indent: 50, endIndent: 10),
                        ),
                        Text(
                          "atau",
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onBackground.withValues(alpha: 0.6),
                          ),
                        ),
                        const Expanded(
                          child: Divider(indent: 10, endIndent: 50),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // DAFTAR: border gradien + background beda untuk light/dark
                    GradientBorderButton(
                      label: "Daftar",
                      borderGradient: daftarBorderGradient,
                      backgroundGradient: isLight
                          ? daftarBgLight
                          : daftarBgDark,
                      textStyle: tt.labelLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      height: 52,
                      radius: 30,
                      borderThickness: 1.5,
                      shadow: true,
                      shadowColor: isLight
                          ? Colors.black.withValues(alpha: .12)
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            // Settings & Help
            // Positioned(
            //   left: 16,
            //   top: 16,
            //   child: IconButton(
            //     tooltip: 'Pengaturan',
            //     icon: Icon(Icons.output, color: cs.onSurface),
            //     onPressed: () async {
            //       if (SplashOverlay.isShowing) return; // cegah double tap
            //       SplashOverlay.show(context);

            //       try {
            //         // prosesmu
            //         await Future.delayed(const Duration(milliseconds: 800));
            //         // tutup overlay DULU supaya transisi route bersih
            //         SplashOverlay.hide();
            //         if (context.mounted) {
            //           Navigator.pushNamed(context, AppRoutes.paymentLauncher);
            //         }
            //       } finally {
            //         // jaga-jaga kalau masih kepasang
            //         if (SplashOverlay.isShowing) SplashOverlay.hide();
            //       }
            //     },
            //   ),
            // ),
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                tooltip: 'Bantuan',
                icon: Icon(Icons.help_outline, color: cs.onBackground),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.help),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashOverlay {
  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show(BuildContext context, {bool dismissible = false}) {
    if (_entry != null) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Blok interaksi & back button
          ModalBarrier(
            dismissible: dismissible,
            color: const Color(0xFF121212), // samakan dengan YAML
          ),
          // Konten splash
          Positioned.fill(
            child: Center(
              child: Image.asset(
                isDark
                    ? 'assets/splash/logo_dark.png'
                    : 'assets/splash/logo.png',
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
