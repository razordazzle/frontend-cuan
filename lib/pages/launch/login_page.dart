import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/components/gradient_border_button.dart';
import 'package:cuan_app/utils/form_styles.dart';
import 'package:cuan_app/utils/validators.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus & Field keys (untuk validasi saat blur/focus lost)
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Gradients
  static const _loginGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00A3A8), Color(0xFF006E72)],
  );
  static const _borderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A9B8), Color(0xFF263238)],
  );
  static const _darkBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
  );

  // helper compose validator
  String? Function(String?) _v(List<String? Function(String?)> vs) {
    return (v) {
      for (final fn in vs) {
        final res = fn(v);
        if (res != null) return res;
      }
      return null;
    };
  }

  void _submit() async {
    // Paksa validasi semua field saat tombol ditekan
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // panggil provider
    final auth = context.read<AuthProvider>();
    final err = await auth.login(email, password);

    if (!mounted) return;

    if (err == null) {
      final me = context.read<AuthProvider>().me; // sudah diisi di login()
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.otpMetode,
        arguments: {
          'email':
              me?.email ?? _emailController.text.trim(), // fallback ke input
          'phone': me?.phone, // bisa null
        },
      );
      // kalau ingin ke home: ganti AppRoutes.main -> AppRoutes.home
    } else {
      // tampilkan error ramah
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
    // debugPrint("Login with $email / $password");
    // Navigator.pushNamed(context, AppRoutes.otpMetode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      // AppBar hanya ikon back
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Masuk",
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Masuk atau daftar hanya dalam beberapa langkah mudah.",
              style: tt.bodyMedium?.copyWith(
                color: cs.onBackground.withValues(alpha: .6),
              ),
            ),
            const SizedBox(height: 28),

            // ===== FORM (tanpa autovalidate) =====
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: AutofillGroup(
                child: Column(
                  children: [
                    // Email (validasi saat blur)
                    Focus(
                      focusNode: _emailFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _emailFieldKey.currentState?.validate();
                        }
                      },
                      child: TextFormField(
                        key: _emailFieldKey,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        textCapitalization: TextCapitalization.none,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: formDecoration(
                          context,
                          label: "Email",
                          prefix: Icon(
                            Icons.email_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .7),
                          ),
                        ),
                        validator: _v([
                          Validators.required(),
                          Validators.email(),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password (validasi saat blur)
                    Focus(
                      focusNode: _passwordFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _passwordFieldKey.currentState?.validate();
                        }
                      },
                      child: TextFormField(
                        key: _passwordFieldKey,
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: formDecoration(
                          context,
                          label: "Password",
                          prefix: Icon(
                            Icons.lock_outline,
                            color: cs.onSurface.withValues(alpha: .7),
                          ),
                          suffix: IconButton(
                            tooltip: _isPasswordVisible
                                ? 'Sembunyikan'
                                : 'Tampilkan',
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: cs.onSurface.withValues(alpha: .7),
                            ),
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),
                        validator: _v([
                          Validators.required('Wajib diisi'),
                          Validators.minLength(8, 'Password'),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ===== Button =====
            if (isLight)
              GradientButton(
                label: "Masuk",
                gradient: _loginGradient,
                textStyle: tt.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                onPressed: _submit,
                height: 52,
                radius: 28,
                shadow: true,
              )
            else
              GradientBorderButton(
                label: "Masuk",
                borderGradient: _borderGradient,
                backgroundGradient: _darkBgGradient,
                textStyle: tt.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                onPressed: _submit,
                height: 52,
                radius: 30,
                borderThickness: 1.5,
                shadow: true,
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
