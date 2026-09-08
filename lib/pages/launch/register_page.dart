import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/components/gradient_border_button.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/utils/form_styles.dart';
import 'package:cuan_app/utils/validators.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Focus & field keys (untuk validasi saat blur)
  final _namaFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _namaFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();

  // Form key
  final _formKey = GlobalKey<FormState>();
  bool _checking = false;
  bool _emailTaken = false;
  bool _phoneTaken = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _namaFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _clearTakenFlags({bool email = false, bool phone = false}) {
    setState(() {
      if (email) _emailTaken = false;
      if (phone) _phoneTaken = false;
    });
  }

  // === Gradients (konsisten) ===
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

  void _continue() async {
    // validasi semua field saat tombol ditekan
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // setState(() => _checking = true);
    setState(() {
      _checking = true;
      // reset flag tiap cek baru
      _emailTaken = false;
      _phoneTaken = false;
    });
    final auth = context.read<AuthProvider>();

    try {
      final existence = await auth.checkAccountExistence(
        email: _emailController.text,
        phoneRaw: _phoneController.text,
      );
      setState(() => _checking = false);

      if (existence != AccountExistence.none) {
        // TANDAI FIELD MANA YANG SUDAH TERDAFTAR → munculkan error inline
        setState(() {
          _emailTaken =
              existence == AccountExistence.email ||
              existence == AccountExistence.both;
          _phoneTaken =
              existence == AccountExistence.phone ||
              existence == AccountExistence.both;
        });
        // Re-validate untuk memunculkan pesan error
        _emailFieldKey.currentState?.validate();
        _phoneFieldKey.currentState?.validate();

        // Tampilkan bottom sheet yang memaksa user login atau ganti input
        _showExistBlockBottomSheet(context, existence: existence);
        return; // ⛔️ JANGAN LANJUT
      }

      // Kalau belum terdaftar → tetap minta persetujuan -> lanjut tambahan
      _showAgreementBottomSheet(
        context,
        onAgree: () {
          auth.saveRegisterStep1(
            name: _namaController.text,
            email: _emailController.text,
            phoneRaw: _phoneController.text,
          );
          Navigator.pushNamed(context, AppRoutes.registerTambahan);
        },
      );
    } catch (e) {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa akun. Coba lagi.')),
      );
    }
  }

  void _showAgreementBottomSheet(
    BuildContext context, {
    required VoidCallback onAgree,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final linkColor = theme.brightness == Brightness.dark
        ? const Color(0xFF00C4CC)
        : cs.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Wrap(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: linkColor, size: 48),
                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Dengan ini saya menyetujui ',
                              ),
                              TextSpan(
                                text: 'Ketentuan Layanan',
                                style: TextStyle(
                                  color: linkColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: linkColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: navigate TOS
                                  },
                              ),
                              const TextSpan(text: ' dan '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                  color: linkColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: linkColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: navigate Privacy
                                  },
                              ),
                              const TextSpan(text: ' dari Cuan.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: "Ya, saya setuju",
                          gradient: _loginGradient,
                          textStyle: tt.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigator.pushNamed(
                            //   context,
                            //   AppRoutes.registerTambahan,
                            // );
                            onAgree();
                          },
                          height: 50,
                          radius: 26,
                          shadow: true,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -20,
                    child: Material(
                      color: cs.surfaceVariant,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.close, color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExistBlockBottomSheet(
    BuildContext context, {
    required AccountExistence existence,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    String desc;
    switch (existence) {
      case AccountExistence.email:
        desc = 'Email yang kamu masukkan sudah terdaftar.';
        break;
      case AccountExistence.phone:
        desc = 'Nomor HP yang kamu masukkan sudah terdaftar.';
        break;
      case AccountExistence.both:
        desc = 'Email dan nomor HP yang kamu masukkan sudah terdaftar.';
        break;
      default:
        desc = '';
    }
    desc += '\nSilakan gunakan data lain atau masuk ke akunmu.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Wrap(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: cs.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Akun Sudah Terdaftar',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          desc,
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: .8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tombol: Ganti Email/No HP (tutup sheet, fokus ke field yang bermasalah)
                        GradientBorderButton(
                          label: "Ganti Email/No HP",
                          borderGradient: _borderGradient,
                          backgroundGradient: _darkBgGradient,
                          textStyle: tt.labelLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          onPressed: () {
                            Navigator.pop(context);

                            setState(() {
                              if (_emailTaken) _emailTaken = false;
                              if (_phoneTaken) _phoneTaken = false;
                            });

                            // 3) Trigger revalidate supaya UI langsung ngebersihin pesan merah
                            _emailFieldKey.currentState?.validate();
                            _phoneFieldKey.currentState?.validate();

                            // arahkan fokus ke field yang relevan
                            if (_emailTaken) {
                              FocusScope.of(context).requestFocus(_emailFocus);
                            } else if (_phoneTaken) {
                              FocusScope.of(context).requestFocus(_phoneFocus);
                            } else {
                              // default: fokuskan ke email dulu
                              FocusScope.of(context).requestFocus(_emailFocus);
                            }
                          },
                          height: 50,
                          radius: 26,
                          borderThickness: 1.5,
                          shadow: true,
                        ),
                        const SizedBox(height: 12),

                        // Tombol: Masuk (navigate ke halaman login)
                        GradientButton(
                          label: "Masuk",
                          gradient: _loginGradient,
                          textStyle: tt.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                          height: 50,
                          radius: 26,
                          shadow: true,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -20,
                    child: Material(
                      color: cs.surfaceVariant,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.close, color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Prefix chip untuk field telepon
  Widget _phonePrefixChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLight ? cs.surface : cs.surface.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? .08 : .20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network('https://flagcdn.com/w20/id.png', width: 20),
          const SizedBox(width: 8),
          Text(
            '+62',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      // AppBar: hanya back
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
              "Daftar",
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

            // ===== FORM (tanpa autovalidate; validasi saat blur) =====
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: AutofillGroup(
                child: Column(
                  children: [
                    // Nama Lengkap
                    Focus(
                      focusNode: _namaFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _namaFieldKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _namaFieldKey,
                        controller: _namaController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_emailFocus),
                        decoration: formDecoration(
                          context,
                          label: "Nama Lengkap",
                        ),
                        validator: _v([
                          Validators.required('Wajib diisi'),
                          Validators.minLength(2, 'Nama'),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    Focus(
                      focusNode: _emailFocus,
                      onFocusChange: (hasFocus) {
                        if (hasFocus && _emailTaken)
                          _clearTakenFlags(email: true);
                        if (!hasFocus) _emailFieldKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _emailFieldKey,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_emailTaken) {
                            _clearTakenFlags(email: true);
                            // optional: revalidate langsung
                            _emailFieldKey.currentState?.validate();
                          }
                        },
                        // autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_phoneFocus),
                        decoration: formDecoration(
                          context,
                          label: "Email",
                          prefix: Icon(
                            Icons.email_outlined,
                            color: cs.onSurface.withValues(alpha: .7),
                          ),
                        ),
                        validator: _v([
                          Validators.required(),
                          Validators.email(),
                          (v) => _emailTaken
                              ? 'Email sudah terdaftar. Gunakan email lain atau login.'
                              : null,
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Label Nomor Hp
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4.0,
                        bottom: 8.0,
                        top: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            text: 'Nomor Hp ',
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onBackground,
                            ),
                            children: [
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: cs.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Nomor Hp
                    Focus(
                      focusNode: _phoneFocus,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _phoneFieldKey.currentState?.validate();
                      },
                      child: TextFormField(
                        key: _phoneFieldKey,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_phoneTaken) {
                            _clearTakenFlags(phone: true);
                            _phoneFieldKey.currentState?.validate();
                          }
                        },
                        // autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) => _continue(),
                        decoration: formDecoration(context, label: "Nomor Hp")
                            .copyWith(
                              prefixIcon: _PrefixInset(
                                child: _phonePrefixChip(context),
                              ),
                            ),
                        validator: _v([
                          Validators.required(),
                          Validators.phoneID(),
                          (v) => _phoneTaken
                              ? 'Nomor HP sudah terdaftar. Gunakan nomor lain atau login.'
                              : null,
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
              // GradientButton(
              //   label: "Lanjutkan",
              //   gradient: _loginGradient,
              //   textStyle: tt.labelLarge?.copyWith(
              //     color: Colors.white,
              //     fontWeight: FontWeight.w700,
              //     fontSize: 18,
              //   ),
              //   onPressed: _continue,
              //   height: 52,
              //   radius: 28,
              //   shadow: true,
              // )
              GradientButton(
                label: _checking ? "Memeriksa..." : "Lanjutkan",
                gradient: _loginGradient,
                textStyle: tt.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                onPressed: _checking ? null : _continue,
                height: 52,
                radius: 28,
                shadow: true,
              )
            else
              // GradientBorderButton(
              //   label: "Lanjutkan",
              //   borderGradient: _borderGradient,
              //   backgroundGradient: _darkBgGradient,
              //   textStyle: tt.labelLarge?.copyWith(
              //     color: cs.onSurface,
              //     fontWeight: FontWeight.w700,
              //     fontSize: 18,
              //   ),
              //   onPressed: _continue,
              //   height: 52,
              //   radius: 30,
              //   borderThickness: 1.5,
              //   shadow: true,
              // ),
              GradientBorderButton(
                label: _checking ? "Memeriksa..." : "Lanjutkan",
                borderGradient: _borderGradient,
                backgroundGradient: _darkBgGradient,
                textStyle: tt.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                onPressed: _checking ? null : _continue,
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

/// Menempatkan child sebagai prefixIcon tapi tetap menjaga ukuran standar input
class _PrefixInset extends StatelessWidget {
  final Widget child;
  const _PrefixInset({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1.0,
      child: Padding(padding: const EdgeInsets.only(left: 6), child: child),
    );
  }
}
