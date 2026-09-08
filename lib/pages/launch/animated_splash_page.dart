import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

class AnimatedSplashPage extends StatefulWidget {
  const AnimatedSplashPage({super.key});
  @override
  State<AnimatedSplashPage> createState() => _AnimatedSplashPageState();
}

class _AnimatedSplashPageState extends State<AnimatedSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();

  @override
  void initState() {
    super.initState();
    // Lepas native splash saat animasi kita mulai
    FlutterNativeSplash.remove();
    // Jalankan animasi sebentar + bootstrap token
    Future.wait([
      Future.delayed(const Duration(milliseconds: 900)), // tunggu animasi
      _bootstrapAuth(),                                 // cek token + fetch /users/me
    ]).then((results) {
      final loggedIn = results[1] as bool;
      if (!mounted) return;

      // Tentukan tujuan akhir:
      // - Kalau sudah login → ke Main/Home
      // - Kalau belum → ke Launch (alur welcome/login kamu)
      Navigator.pushReplacementNamed(
        context,
        loggedIn ? AppRoutes.main : AppRoutes.launch,
      );
    });
  }

    Future<bool> _bootstrapAuth() async {
    try {
      final ok = await context.read<AuthProvider>().bootstrap();
      return ok;
    } catch (_) {
      return false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
          child: Image.asset('assets/splash/logo.png', width: 140),
        ),
      ),
    );
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }
}
