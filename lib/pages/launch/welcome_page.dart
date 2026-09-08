import 'dart:async';

import 'package:cuan_app/components/gradient_text.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatefulWidget {
  final String displayName;
  final String? avatarUrl;
  const WelcomePage({super.key, required this.displayName, this.avatarUrl});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Timer? _t;

  // brand gradient: turquoise → teal (sesuai yang kita pakai di Launch/Login)
  static const _brand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00A3A8), Color(0xFF006E72)],
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // tampil 1.8 detik lalu ke MainPage
    _t = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    // final avatarUrl = auth.avatarUrl;

    return PopScope(
      canPop: false, // blok back: user tidak bisa kembali ke OTP
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return; // sudah pop, tidak perlu apa-apa
        // Belum pop karena kita blok. Di sini kamu bisa kasih feedback, logging, dll.
        // ScaffoldMessenger.of(context).showSnackBar(...);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: widget.avatarUrl != null
                      ? NetworkImage(widget.avatarUrl!)
                      : null,
                  child: widget.avatarUrl == null
                      ? Icon(Icons.person, color: cs.onSurface, size: 40)
                      : null,
                ),
                const SizedBox(height: 24),
                // "Halo, User" (User ber-gradient)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halo, ',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onBackground,
                      ),
                    ),
                    GradientText(
                      name.isEmpty ? 'User' : name,
                      gradient: _brand,
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
