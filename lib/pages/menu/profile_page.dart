// lib/pages/screen/profile_page.dart
import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/request/update_me_request.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // dummy data (bisa kamu isi dari API/user session)
  final _fullnameCtrl = TextEditingController(text: 'Testing');
  final _birthPlaceCtrl = TextEditingController(text: 'Testing');
  final _birthDateCtrl = TextEditingController(text: 'Testing');
  final _domicileCtrl = TextEditingController(text: 'Testing');
  final _emailCtrl = TextEditingController(text: 'Testing');
  final _phoneCtrl = TextEditingController(text: 'Testing');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.me == null) {
        auth.refreshMe();
      }
    });
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void showLogoutSheet(BuildContext context, {VoidCallback? onConfirm}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // kalau kamu sudah punya _loginGradient, ganti variable ini ke punyamu
    const _logoutGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00B8D4), Color(0xFF0077B6)],
    );

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
                        Icon(Icons.info_outline, color: cs.primary, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          '“Apakah Anda yakin ingin keluar? Setelah keluar, '
                          'Anda harus masuk kembali.\nApakah Anda yakin?”',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: .85),
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: "Logout",
                          gradient:
                              _logoutGradient, // atau _loginGradient milikmu
                          textStyle: tt.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          height: 52,
                          radius: 28,
                          shadow: true,
                          onPressed: () {
                            Navigator.pop(context); // tutup sheet
                            onConfirm?.call(); // eksekusi logout nyata
                          },
                        ),
                      ],
                    ),
                  ),

                  // tombol X di pojok atas
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

  @override
  void dispose() {
    _fullnameCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _birthDateCtrl.dispose();
    _domicileCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final auth = context.watch<AuthProvider>();
    final me = auth.me;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Profil')),
      body: auth.loading && me == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // ===== Header (Avatar + Name) =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 6),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: const NetworkImage(
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop',
                          ),
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                        // badge kecil di pojok
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.edit,
                              size: 12,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me?.name ?? '-',
                            style: t.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 16, color: cs.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Account',
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ===== Form (read-only saat _isEdit == false) =====
                _DisabledField(label: 'Nama Lengkap', value: me?.name ?? '-'),
                _DisabledField(label: 'Username', value: me?.username ?? '-'),
                _DisabledField(
                  label: 'Tempat Lahir',
                  value: me?.birthPlace ?? '-',
                ),
                _DisabledField(
                  label: 'Tanggal Lahir',
                  value: me?.birthDate ?? '-',
                ),
                _DisabledField(label: 'Domisili', value: me?.domicile ?? '-'),
                _DisabledField(label: 'Email', value: me?.email ?? '-'),
                _DisabledField(label: 'Nomor Telepon', value: me?.phone ?? '-'),
                const SizedBox(height: 4),
                // ===== Edit Profile? → halaman baru
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        AppRoutes.editProfile,
                        arguments: {
                          'name': me?.name ?? '',
                          'username': me?.username ?? '',
                          'birthPlace': me?.birthPlace ?? '',
                          'birthDate': me?.birthDate ?? '',
                          'domicile': me?.domicile ?? '',
                          'phone': me?.phone ?? '',
                        },
                      );
                      // Jika halaman edit mengembalikan map perubahan → panggil update
                      if (result is Map<String, dynamic> && result.isNotEmpty) {
                        final req = UpdateMeRequest(
                          name: result['name'],
                          username: result['username'],
                          birthPlace: result['birthPlace'],
                          birthDate: result['birthDate'],
                          domicile: result['domicile'],
                          phone: result['phone'],
                        );
                        final err = await context
                            .read<AuthProvider>()
                            .updateProfile(req);
                        if (!mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(err)));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil tersimpan')),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Edit Profile?',
                            style: t.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ===== Logout =====
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showLogoutSheet(context, onConfirm: _logout);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(56),
                      side: BorderSide(color: cs.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ================== widgets ================== */

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey(value),
            initialValue: value,
            enabled: false,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withOpacity(.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
