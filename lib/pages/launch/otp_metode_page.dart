import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/pages/launch/otp_insert_page.dart';
import 'package:provider/provider.dart'; // enum OtpVerificationType

class OtpMetodePage extends StatefulWidget {
  const OtpMetodePage({super.key});

  @override
  State<OtpMetodePage> createState() => _OtpMetodePageState();
}

class _OtpMetodePageState extends State<OtpMetodePage> {
  bool _loading = false;
  // Konsisten dengan halaman lain
  static const _borderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A9B8), Color(0xFF263238)],
  );
  String _maskEmail(String? email) {
    if (email == null || email.isEmpty || !email.contains('@')) return '—';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    final shown = name.length <= 2 ? name[0] : '${name.substring(0, 2)}';
    return '$shown***@${domain}';
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '—';
    final digits = phone.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 6) return '${digits.substring(0, 2)}***';
    final start = digits.substring(0, 3);
    final end = digits.substring(digits.length - 3);
    return '$start****$end';
    // contoh: +6281234567890 -> +62****890
  }

  Future<void> _chooseAndRequest(
    OtpVerificationType type, {
    required String displayContact,
  }) async {
    setState(() => _loading = true);
    try {
      // panggil provider untuk request OTP
      // Saran: buat method di AuthProvider, mis. requestOtp(type)
      // Di sini aku contohkan langsung panggil ke service via provider.
      final auth = context.read<AuthProvider>();

      // === GANTI BAGIAN INI sesuai implementasi kamu ===
      // Contoh method baru di AuthProvider (silakan tambahkan):
      // Future<(String challengeId, int expiresIn)?> requestOtp(OtpVerificationType type)
      //
      // Untuk sementara, aku akali dengan asumsi method tersebut ada:
      final challenge = await auth.requestOtp(
        type,
      ); // <-- implement di provider
      if (!mounted) return;

      if (challenge == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim OTP. Coba lagi.')),
        );
        return;
      }

      final (challengeId, expiresIn, codeDev) = challenge;
      // INFO: tampilkan codeDev untuk testing DEV saja
      if (codeDev != null && codeDev.isNotEmpty) {
        // SnackBar/Alert dialog — pilih salah satu
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kode DEV: $codeDev')));
      }

      // pindah ke halaman input OTP sambil kirim data
      Navigator.pushNamed(
        context,
        AppRoutes.otpInsert,
        arguments: {
          'type': type,
          'contact': displayContact,
          'challengeId': challengeId,
          'expiresIn': expiresIn, // detik
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Ambil data user dari provider
    final me = context.watch<AuthProvider>().me;

    // Ambil juga argumen dari LoginPage (opsional; fallback kalau me null)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = me?.email ?? args?['email'] as String?;
    final phone = me?.phone; // pastikan diisi setelah /users/me

    // BG dalam tile: light = abu terang, dark = gelap
    final innerGradient = isLight
        ? const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF3F3F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Colors.grey[850]!, Colors.black.withValues(alpha: .95)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      // Biarkan AppBar ikut tema (jangan hardcode warna putih)
      appBar: AppBar(
        title: Text(
          'Pilih Metode Verifikasi',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30.0,
            ),
            child: Column(
              children: [
                GradientOptionTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'OTP via WhatsApp',
                  subtitle: _maskPhone(phone),
                  borderGradient: _borderGradient,
                  backgroundGradient: innerGradient,
                  textColor: cs.onSurface,
                  onTap: phone == null || phone.isEmpty || _loading
                      ? null
                      : () => _chooseAndRequest(
                          OtpVerificationType.whatsapp,
                          displayContact: _maskPhone(phone),
                        ),
                ),
                const SizedBox(height: 16),
                GradientOptionTile(
                  icon: Icons.email_outlined,
                  title: 'OTP via Email',
                  subtitle: _maskEmail(email),
                  borderGradient: _borderGradient,
                  backgroundGradient: innerGradient,
                  textColor: cs.onSurface,
                  onTap: email == null || email.isEmpty || _loading
                      ? null
                      : () => _chooseAndRequest(
                          OtpVerificationType.email,
                          displayContact: _maskEmail(email),
                        ),
                ),
                if ((phone == null || phone.isEmpty) ||
                    (email == null || email.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Beberapa metode tidak tersedia karena data kontak belum lengkap. '
                      'Perbarui di Profil.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// Tile dengan border gradient + inner gradient (tema-aware)
class GradientOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final LinearGradient borderGradient;
  final Gradient backgroundGradient;
  final Color textColor;

  const GradientOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.borderGradient,
    required this.backgroundGradient,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final cs = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: borderGradient,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(1.5), // ketebalan border
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16.5,
                ),
                decoration: BoxDecoration(
                  gradient: backgroundGradient,
                  borderRadius: BorderRadius.circular(28.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: textColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(.65),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
