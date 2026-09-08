import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/components/gradient_border_button.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/utils/form_styles.dart';
import 'package:cuan_app/utils/validators.dart';
import 'package:provider/provider.dart';

class RegisterTambahan extends StatefulWidget {
  const RegisterTambahan({super.key});

  @override
  State<RegisterTambahan> createState() => _RegisterTambahanState();
}

class _RegisterTambahanState extends State<RegisterTambahan> {
  // Controllers
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _pobController = TextEditingController();
  final _domicileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus & Field Keys (untuk validasi saat blur)
  final _usernameFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _pobFocus = FocusNode();
  final _domicileFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final _usernameKey = GlobalKey<FormFieldState<String>>();
  final _dobKey = GlobalKey<FormFieldState<String>>();
  final _pobKey = GlobalKey<FormFieldState<String>>();
  final _domicileKey = GlobalKey<FormFieldState<String>>();
  final _passwordKey = GlobalKey<FormFieldState<String>>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();

  // Form key
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _submitting = false;
  @override
  void dispose() {
    _usernameController.dispose();
    _dobController.dispose();
    _pobController.dispose();
    _domicileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _usernameFocus.dispose();
    _dobFocus.dispose();
    _pobFocus.dispose();
    _domicileFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // === Gradient tokens (selaras dgn Login/Register) ===
  static const _filledTeal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00A3A8), Color(0xFF006E72)],
  );
  static const _borderCyanToBlueGrey = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A9B8), Color(0xFF263238)],
  );
  static const _darkBg = LinearGradient(
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

  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const brand = Color(0xFF00A3A8);

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) {
        // Pastikan tombol Cancel/OK kontras di dark mode
        return Theme(
          data: theme.copyWith(
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: brand),
            ),
            colorScheme: cs.copyWith(primary: brand, onPrimary: Colors.white),
            dialogTheme: theme.dialogTheme.copyWith(
              backgroundColor: cs.surface,
              surfaceTintColor: cs.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobController.text =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
      // trigger validasi DOB setelah pilih
      _dobKey.currentState?.validate();
    }
  }

  void _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

   setState(() => _submitting = true);

  final auth = context.read<AuthProvider>();
  final err = await auth.submitRegister(
    password: _passwordController.text,
    username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
    birthPlace: _pobController.text.trim().isEmpty ? null : _pobController.text.trim(),
    birthDate: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(), // "YYYY-MM-DD"
    domicile: _domicileController.text.trim().isEmpty ? null : _domicileController.text.trim(),
    // pilih salah satu:
    // autoLogin: false, // → setelah register, arahkan ke login
    autoLogin: true,      // → setelah register, langsung login
  );

  setState(() => _submitting = false);

  if (err == null) {
    // Sukses:
    // Jika autoLogin=false → ke halaman login
    // Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);

    // Jika autoLogin=true dan kamu mau verifikasi OTP → sekarang sudah punya token
    Navigator.pushNamed(context, AppRoutes.otpMetode);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

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
            const SizedBox(height: 4),
            Text(
              "Informasi Tambahan",
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Masukkan username dan password Anda untuk \nmelengkapi proses buat akun",
              style: tt.bodyMedium?.copyWith(
                color: cs.onBackground.withValues(alpha: .6),
              ),
            ),

            const SizedBox(height: 28),

            // ===== FORM (tanpa autovalidate; validasi saat blur) =====
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: AutofillGroup(
                child: Column(
                  children: [
                    // Username
                    Focus(
                      focusNode: _usernameFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _usernameKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _usernameKey,
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_dobFocus),
                        decoration: formDecoration(
                          context,
                          label: "Username",
                          hint: "Enter Username",
                          prefix: Icon(Icons.person_outline,
                              color: cs.onSurface.withValues(alpha: .7)),
                        ),
                        validator: _v(
                          [Validators.required('Wajib diisi'), Validators.minLength(3, 'Username')],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Lahir (readOnly + date picker)
                    Focus(
                      focusNode: _dobFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _dobKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _dobKey,
                        controller: _dobController,
                        readOnly: true,
                        onTap: _pickDate,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_pobFocus),
                        decoration: formDecoration(
                          context,
                          label: "Tanggal Lahir",
                          hint: "YYYY-MM-DD",
                          prefix: Icon(Icons.calendar_today_outlined,
                              color: cs.onSurface.withValues(alpha: .7)),
                          suffix: IconButton(
                            tooltip: 'Pilih tanggal',
                            icon: Icon(Icons.event,
                                color: cs.onSurface.withValues(alpha: .7)),
                            onPressed: _pickDate,
                          ),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Wajib diisi';
                          // terima format yyyy-mm-dd sederhana
                          final dt = DateTime.tryParse(s);
                          return dt == null ? 'Format tidak valid' : null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tempat Lahir
                    Focus(
                      focusNode: _pobFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _pobKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _pobKey,
                        controller: _pobController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_domicileFocus),
                        decoration: formDecoration(
                          context,
                          label: "Tempat Lahir",
                          hint: "Enter Place of Birth",
                          prefix: Icon(Icons.location_on_outlined,
                              color: cs.onSurface.withValues(alpha: .7)),
                        ),
                        validator: _v([Validators.required('Wajib diisi')]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Domisili
                    Focus(
                      focusNode: _domicileFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _domicileKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _domicileKey,
                        controller: _domicileController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        decoration: formDecoration(
                          context,
                          label: "Domisili",
                          hint: "Enter Domicile",
                          prefix: Icon(Icons.home_outlined,
                              color: cs.onSurface.withValues(alpha: .7)),
                        ),
                        validator: _v([Validators.required('Wajib diisi')]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Focus(
                      focusNode: _passwordFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _passwordKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _passwordKey,
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_confirmFocus),
                        decoration: formDecoration(
                          context,
                          label: "Password",
                          hint: "Enter Password",
                          prefix: Icon(Icons.lock_outline,
                              color: cs.onSurface.withValues(alpha: .7)),
                          suffix: IconButton(
                            tooltip:
                                _isPasswordVisible ? 'Sembunyikan' : 'Tampilkan',
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: cs.onSurface.withValues(alpha: .7),
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: _v(
                          [Validators.required('Wajib diisi'), Validators.minLength(6, 'Password')],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Konfirmasi Password
                    Focus(
                      focusNode: _confirmFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _confirmKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _confirmKey,
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: formDecoration(
                          context,
                          label: "Konfirmasi Password",
                          hint: "Confirm Password",
                          prefix: Icon(Icons.lock_outline,
                              color: cs.onSurface.withValues(alpha: .7)),
                          suffix: IconButton(
                            tooltip: _isConfirmPasswordVisible
                                ? 'Sembunyikan'
                                : 'Tampilkan',
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: cs.onSurface.withValues(alpha: .7),
                            ),
                            onPressed: () => setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible),
                          ),
                        ),
                        validator: _v([
                          Validators.required('Wajib diisi'),
                          Validators.match(_passwordController, 'Konfirmasi tidak cocok'),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ===== Button: light = filled teal, dark = gradient border =====
            if (isLight)
              GradientButton(
                label: "Daftar",
                gradient: _filledTeal,
                textStyle: tt.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                onPressed: _submitting ? null : _submit,
                height: 52,
                radius: 28,
                shadow: true,
              )
            else
              GradientBorderButton(
                label: "Daftar",
                borderGradient: _borderCyanToBlueGrey,
                backgroundGradient: _darkBg,
                textStyle: tt.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                onPressed: _submitting ? null : _submit,
                height: 52,
                radius: 30,
                borderThickness: 1.5,
                shadow: true,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
