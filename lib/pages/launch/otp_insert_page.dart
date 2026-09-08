import 'dart:async';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cuan_app/utils/form_styles.dart';
import 'package:cuan_app/components/gradient_border_button.dart';
import 'package:provider/provider.dart';

// Tetap di file ini ya biar gampang dipakai di AppRoutes (alias import)
enum OtpVerificationType { whatsapp, email }

class OtpInsertPage extends StatefulWidget {
  final OtpVerificationType verificationType;
  final String contactInfo;

  final String? challengeId;
  final int? expiresIn; // detik

  const OtpInsertPage({
    super.key,
    required this.verificationType,
    required this.contactInfo,
    this.challengeId,
    this.expiresIn,
  });

  @override
  State<OtpInsertPage> createState() => _OtpInsertPageState();
}

class _OtpInsertPageState extends State<OtpInsertPage> {
  final _otpController = TextEditingController();
  final _otpFieldKey = GlobalKey<FormFieldState<String>>();
  final _otpFocus = FocusNode();
  bool _submitting = false;
  String? _error;

  Timer? _timer;
  int _secondsLeft = 0;
  String? _challengeId; // aktif

  // gradient tokens (konsisten layar lain)
  static const _borderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A9B8), Color(0xFF263238)],
  );
  static const _darkBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
  );
  static const _lightBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF3F3F3)],
  );

  bool _hydrated = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;

    // Aman mengakses context di sini
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // ambil challengeId & expiresIn dari widget.* dulu, fallback ke args
    _challengeId = widget.challengeId ?? args?['challengeId'] as String?;
    final exp = widget.expiresIn ?? (args?['expiresIn'] as int?);

    _startTimer((exp ?? 120)); // default 120 detik
    _hydrated = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verifyOtp(String code) async {
    if (_submitting) return;
    if (_challengeId == null) {
      setState(() => _error = 'Sesi OTP tidak ditemukan. Coba kirim ulang.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final ok = await context.read<AuthProvider>().verifyOtp(
        challengeId: _challengeId!,
        code: code,
      );

      if (!mounted) return;
      if (ok) {
        // sukses → masuk halaman utama (atau welcome) dan bersihkan stack
        final auth = context.read<AuthProvider>();
        if (auth.me == null) {
          await auth.refreshMe(); // pastikan nama sudah terambil
        }
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome, // sekarang tidak kirim argumen
          (route) => false,
        );
      } else {
        setState(() => _error = 'Kode OTP salah atau kadaluarsa');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal verifikasi. Periksa jaringan kamu.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resend() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final challenge = await context.read<AuthProvider>().requestOtp(
        widget.verificationType,
      );
      if (!mounted) return;

      if (challenge == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim ulang OTP. Coba lagi.')),
        );
        return;
      }

      final (newChallengeId, expiresIn, codeDev) = challenge;
      _challengeId = newChallengeId;
      _startTimer(expiresIn);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP dikirim ulang')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kesalahan jaringan saat kirim ulang.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;
    const brand = Color(0xFF00A3A8);

    final title = widget.verificationType == OtpVerificationType.whatsapp
        ? RichText(
            text: TextSpan(
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onBackground,
              ),
              children: const [
                TextSpan(text: 'Cek '),
                TextSpan(
                  text: 'WhatsApp',
                  style: TextStyle(color: brand),
                ),
                TextSpan(text: ', ya'),
              ],
            ),
          )
        : RichText(
            text: TextSpan(
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onBackground,
              ),
              children: const [
                TextSpan(text: 'Masukkan OTP yang kami kirim ke '),
                TextSpan(
                  text: 'Email',
                  style: TextStyle(color: brand),
                ),
              ],
            ),
          );

    // background untuk tombol sekunder
    final innerBg = isLight ? _lightBg : _darkBg;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 4),
            title,
            const SizedBox(height: 6),
            Text(
              "Kode-nya kami kirim ke ${widget.contactInfo}",
              style: tt.bodyMedium?.copyWith(
                color: cs.onBackground.withOpacity(.6),
              ),
            ),

            const SizedBox(height: 24),

            // Label OTP
            RichText(
              text: TextSpan(
                style: tt.bodyMedium?.copyWith(color: cs.onBackground),
                children: const [
                  TextSpan(text: 'OTP '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Field OTP (validasi saat blur + seconds suffix)
            Focus(
              focusNode: _otpFocus,
              onFocusChange: (hasFocus) {
                if (!hasFocus) _otpFieldKey.currentState?.validate();
              },
              child: TextFormField(
                key: _otpFieldKey,
                controller: _otpController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textAlignVertical:
                    TextAlignVertical.center, // <-- pusat vertikal
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                decoration:
                    formDecoration(
                      context,
                      label: 'Kode',
                      hint: 'Kode',
                      // ❌ JANGAN kirim 'suffix:' di sini lagi
                    ).copyWith(
                      // ✅ Pakai suffixIcon biar center
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Align(
                          alignment: Alignment.center,
                          widthFactor: 1.0,
                          child: _secondsLeft > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isLight
                                        ? cs.surface
                                        : cs.surface.withOpacity(.2)),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: cs.outline.withOpacity(.25),
                                    ),
                                  ),
                                  child: Text(
                                    '${_secondsLeft}s',
                                    style: tt.labelMedium?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: _resend,
                                  child: const Text('Kirim ulang'),
                                ),
                        ),
                      ),
                      // hilangkan constraint default supaya badge pas
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),

                      // (opsional) radius & padding seperti mockup
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: cs.outline.withOpacity(isLight ? .5 : .3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: cs.primary, width: 1.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                onChanged: (v) {
                  if (v.trim().length == 6) {
                    _verifyOtp(v.trim());
                  }
                },
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Wajib diisi';
                  if (s.length < 6) return 'Masukkan 6 digit kode';
                  return null;
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Colors.red[400])),
            ],
            const SizedBox(height: 28),

            // Tombol sekunder (gradient-border gelap) — sesuai screenshot
            GradientBorderButton(
              label: "Coba Metode Lainnya",
              borderGradient: _borderGradient,
              backgroundGradient: innerBg,
              textStyle: tt.labelLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
              onPressed: () => Navigator.pop(context),
              height: 48,
              radius: 28,
              borderThickness: 1.5,
              shadow: true,
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
