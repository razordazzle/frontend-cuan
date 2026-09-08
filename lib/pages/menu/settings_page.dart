import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/styles/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _requestedProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tarik profil sekali bila belum ada
    final auth = context.read<AuthProvider>();
    if (!_requestedProfile && auth.me == null && !auth.loading) {
      _requestedProfile = true;
      // post-frame supaya aman dari build pertama
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) auth.refreshMe();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final tt = t.textTheme;
    final c = context.watch<ThemeController>();
    final auth = context.watch<AuthProvider>();
    final me = auth.me;

    // switch dianggap ON kalau dark atau system+device dark
    final bool isDarkNow = t.brightness == Brightness.dark;
    final bool switchValue =
        c.mode == ThemeMode.dark || (c.mode == ThemeMode.system && isDarkNow);

    final String displayName = (me?.name.trim().isNotEmpty == true)
        ? me!.name.trim()
        : 'User';
    final String subtitle = [
      if (me?.username?.isNotEmpty == true) '@${me!.username!}',
      me?.email,
    ].where((e) => e != null && e.isNotEmpty).join(' • ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEB3B),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 12),

          // ==== Profile ====
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.surfaceVariant,
                  child: Icon(Icons.person, color: cs.onSurface, size: 36),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onBackground,
                      ),
                    ),
                    if (auth.loading) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onBackground.withOpacity(.6),
                    ),
                  ),
                if (me?.phone?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    me!.phone!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onBackground.withOpacity(.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _Line(),

          // ==== Items ====
          _SettingsItem(
            label: 'Your Profile',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          const _Line(),
          _SettingsItem(
            label: 'Terms & Condition',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.terms);
            },
          ),
          const _Line(),
          _SettingsItem(
            label: 'Help',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.help);
            },
          ),
          const _Line(),
          _SettingsItem(
            label: 'About',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.aboutUs);
            },
          ),
          const _Line(),

          // ==== Tema Mode ====
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tema Mode',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onBackground,
                    ),
                  ),
                ),
                // switch dengan ikon kecil di thumb
                Theme(
                  data: t.copyWith(
                    switchTheme: t.switchTheme.copyWith(
                      thumbIcon: const WidgetStatePropertyAll(
                        Icon(Icons.nights_stay_rounded, size: 14),
                      ),
                    ),
                  ),
                  child: Switch.adaptive(
                    value: switchValue,
                    onChanged: (v) {
                      // ON = dark, OFF = light (kalau mau dukung 'system', bikin tombol/opsi terpisah)
                      context.read<ThemeController>().setMode(
                        v ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const _Line(),

          _SettingsItem(
            label: 'Logout',
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Keluar akun?'),
                  content: const Text('Kamu akan keluar dari aplikasi.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;

              // 1) Bersihkan session sesuai implementasi kamu (pilih salah satu)
              // a) Provider / Auth controller
              // await context.read<AuthController>().logout();

              // b) FirebaseAuth
              // await FirebaseAuth.instance.signOut();

              // c) SharedPreferences (contoh sederhana)
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.remove('auth_token'); // dsb.

              if (!context.mounted) return;

              // 2) Kembali ke halaman awal & hapus semua history
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.launch, // '/' sesuai routes-mu
                (route) => false,
              );
            },
          ),
          const _Line(),

          const SizedBox(height: 16),

          // ==== Footer ====
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Text(
                  'Cuan – Version 1.0',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onBackground.withOpacity(.6),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Terms of use'),
                    ),
                    Text(
                      '|',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onBackground.withOpacity(.4),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Privacy policy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SettingsItem({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onBackground,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(.5)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(height: 1, thickness: 1, color: cs.outline.withOpacity(.3));
  }
}
