import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuan_app/config/app_routes.dart';

class ReadmePage extends StatefulWidget {
  /// kunci flag penyimpanan (biar bisa beda-beda untuk tiap konteks)
  final String prefKey;

  /// true = selesai -> Navigator.pop(); false = pushReplacementNamed(nextRoute)
  final bool popInsteadOfReplace;
  final String? nextRoute;

  const ReadmePage({
    super.key,
    this.prefKey = 'has_onboarded_v1',
    this.popInsteadOfReplace = false,
    this.nextRoute,
  });
  @override
  State<ReadmePage> createState() => _ReadmePageState();
}

class _ReadmePageState extends State<ReadmePage> {
  final _c = PageController();
  int _index = 0;

  static const _brandCyan = Color(0xFF00A3A8);

  final _slides = const [
    _OnboardSlide(
      image: 'assets/readme/readme_1.png', // ganti sesuai asetmu
      title: 'Mulailah Perjalanan Anda\ndengan mudah!',
      body:
          'Kami sudah menyiapkan panduan singkat agar Anda lebih siap sebelum mulai belajar. '
          'Dengan langkah yang sederhana, Anda bisa memahami dasar-dasar aplikasi dan memaksimalkan setiap fitur yang tersedia.',
    ),
    _OnboardSlide(
      image: 'assets/readme/readme_2.png',
      title: 'Belajar jadi lebih efisien.',
      body:
          'Setiap materi disusun secara terarah dan bertahap. Anda akan menemukan tips praktis, ilustrasi interaktif, '
          'serta contoh nyata yang membantu memperdalam pemahaman.',
    ),
    _OnboardSlide(
      image: 'assets/readme/readme_3.png',
      title: 'Gapai potensi terbaik\nAnda.',
      body:
          'Belajar bukan sekadar memahami teori, tapi juga mengaplikasikannya. '
          'Dengan konsistensi dan semangat, Anda akan semakin percaya diri dalam dunia finansial.',
    ),
  ];

  Future<void> _finish() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(widget.prefKey, true);
    if (!mounted) return;

    if (widget.popInsteadOfReplace) {
      Navigator.pop(context); // kembali ke halaman yang memanggil
    } else {
      final route = widget.nextRoute ?? AppRoutes.modul;
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final s in _slides) {
      precacheImage(AssetImage(s.image), context);
    }

    precacheImage(const AssetImage('assets/splash/logo.png'), context);
  }

  final double _imageHeight = 260.0; // atur sesuai selera/UI
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // --- layout numbers (disesuaikan UI) ---
    const double contentMaxWidth = 420; // batas lebar teks agar rapi
    final double h = MediaQuery.sizeOf(context).height;
    final double imageZone =
        h * 0.42; // area gambar + dots (≈ 42% tinggi layar)
    final double imgHeight =
        imageZone - 26; // ruang gambar (sisanya untuk dots + gap)
    final bool isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      height: 28, // samakan kira2 proporsi mockup status bar
                      child: Image.asset(
                        'assets/splash/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Teks brand
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CUAN',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00A3A8),
                                letterSpacing: .5,
                              ),
                        ),
                        Text(
                          'DIGITAL NUSANTARA',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(.85),
                                letterSpacing: 1.1,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Spacer(),
            // === Gambar + Dots (tinggi terukur, bukan Expanded) ===
            SizedBox(
              height: imageZone,
              child: PageView.builder(
                controller: _c,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: imgHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: Image.asset(s.image, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dots tepat di bawah gambar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (d) {
                          final active = d == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: active ? 18 : 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF00A3A8)
                                  : cs.onSurface.withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),

            // const SizedBox(height: 12),
            Spacer(),

            // === Title ===
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _slides[_index].title,
                    textAlign: TextAlign.center,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),

            Spacer(),
            // === Body ===
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _slides[_index].body,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: .70),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // const SizedBox(height: 16),
            Spacer(),

            // === Tombol (Skip di kiri Lanjut; keduanya center) ===
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isLast)
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Skip'),
                        ),
                      if (!isLast) const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3A8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation:
                              Theme.of(context).brightness == Brightness.dark
                              ? 2
                              : 1,
                        ),
                        onPressed: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _c.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Text(
                          isLast ? 'Lanjutkan Belajar' : 'Lanjut',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide {
  final String image;
  final String title;
  final String body;
  const _OnboardSlide({
    required this.image,
    required this.title,
    required this.body,
  });
}
