import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:cuan_app/config/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final ok = await context.read<AuthProvider>().bootstrap();
      FlutterNativeSplash.remove(); // ⬅️ lepas splash bawaan plugin
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(ok ? AppRoutes.home : AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    // kalau mau, tampilkan animasi/logo custom sambil bootstrap
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
