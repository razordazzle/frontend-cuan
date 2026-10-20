import 'package:cuan_app/components/gradient_border_button.dart';
import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/data/services/auth_service.dart';
import 'package:cuan_app/utils/form_styles.dart';
import 'package:cuan_app/utils/validators.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Alur lupa password (sesuai desain):
/// Login -> "Lupa password?" -> halaman Lupa Password (isi email; email tidak terdaftar diberi tahu)
/// -> pop-up konfirmasi -> "Ya, saya setuju" -> backend kirim link atur ulang password ke email
/// -> halaman berhasil -> "Kembali" -> halaman login.
/// Password baru dibuat di halaman web dari link di email, bukan di dalam app.

const _tealGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF00A3A8), Color(0xFF006E72)],
);
const _borderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF00A9B8), Color(0xFF263238)],
);
const _darkBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
);

String _networkMessage(DioException e) {
  final offline =
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;
  return offline
      ? 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.'
      : 'Gagal mengirim permintaan. Silakan coba lagi.';
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  /// Email yang sudah diketik di halaman login, biar user tidak perlu mengetik ulang
  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );

  bool _checking = false;
  String? _emailError; // mis. "Email tidak terdaftar" (dari server)

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_checking) return;
    setState(() => _emailError = null);
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final email = _emailController.text.trim();
    setState(() => _checking = true);
    bool registered;
    try {
      registered = await context.read<AuthService>().isEmailRegistered(email);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_networkMessage(e))));
      return;
    }
    if (!mounted) return;
    setState(() => _checking = false);

    if (!registered) {
      setState(
        () => _emailError =
            'Email tidak terdaftar. Mohon periksa kembali email Anda.',
      );
      return;
    }

    final sent = await showForgotPasswordConfirm(context, email);
    if (sent == true && mounted) {
      // Ganti halaman ini dengan halaman berhasil -> "Kembali" langsung ke halaman login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ForgotPasswordSentPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    final buttonText = tt.labelLarge?.copyWith(
      color: isLight ? Colors.white : cs.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    );
    final label = _checking ? 'Memeriksa...' : 'Kirim';
    final VoidCallback? onPressed = _checking ? null : _submit;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lupa Password',
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Masukan email Anda',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: .7),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                onFieldSubmitted: (_) => _submit(),
                decoration: formDecoration(
                  context,
                  label: 'Enter Email',
                  suffix: Icon(
                    Icons.mail_outline,
                    color: cs.onSurface.withValues(alpha: .7),
                  ),
                ).copyWith(errorText: _emailError, errorMaxLines: 2),
                validator: (v) =>
                    Validators.required()(v) ?? Validators.email()(v),
              ),
            ),
            const SizedBox(height: 28),
            if (isLight)
              GradientButton(
                label: label,
                gradient: _tealGradient,
                textStyle: buttonText,
                onPressed: onPressed,
                height: 48,
                radius: 24,
                shadow: true,
              )
            else
              GradientBorderButton(
                label: label,
                borderGradient: _borderGradient,
                backgroundGradient: _darkBgGradient,
                textStyle: buttonText,
                onPressed: onPressed,
                height: 48,
                radius: 24,
                borderThickness: 1.5,
                shadow: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// Pop-up konfirmasi. true = disetujui & link reset terkirim ke [email].
Future<bool?> showForgotPasswordConfirm(BuildContext context, String email) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .6),
    builder: (_) => _ForgotPasswordConfirmSheet(email: email),
  );
}

class _ForgotPasswordConfirmSheet extends StatefulWidget {
  const _ForgotPasswordConfirmSheet({required this.email});

  final String email;

  @override
  State<_ForgotPasswordConfirmSheet> createState() =>
      _ForgotPasswordConfirmSheetState();
}

class _ForgotPasswordConfirmSheetState
    extends State<_ForgotPasswordConfirmSheet> {
  bool _loading = false;

  Future<void> _agree() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().forgotPassword(widget.email);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_networkMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Tombol tutup bulat di atas kanan pop-up
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 12),
          child: Material(
            color: cs.inverseSurface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _loading ? null : () => Navigator.pop(context, false),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(Icons.close, color: cs.onInverseSurface, size: 26),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(28, 36, 28, 36 + bottomInset),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: cs.onSurface.withValues(alpha: .55),
                child: Icon(Icons.info, size: 40, color: cs.surface),
              ),
              const SizedBox(height: 24),
              Text(
                'Apakah Anda yakin ingin melakukan mengatur ulang password Anda?',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: .8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 190,
                child: GradientButton(
                  label: _loading ? 'Mengirim...' : 'Ya, saya setuju',
                  gradient: _tealGradient,
                  textStyle: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  onPressed: _loading ? null : _agree,
                  height: 52,
                  radius: 26,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Halaman setelah link reset dikirim. "Kembali" (atau tombol back HP) -> kembali ke login.
class ForgotPasswordSentPage extends StatelessWidget {
  const ForgotPasswordSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengaturan ulang password berhasil dilakukan.\nSilakan cek email Anda',
                  textAlign: TextAlign.center,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 150,
                  child: GradientButton(
                    label: 'Kembali',
                    gradient: _tealGradient,
                    textStyle: tt.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: () => Navigator.pop(context),
                    height: 48,
                    radius: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
