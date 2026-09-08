import 'package:cuan_app/components/gradient_button.dart';
import 'package:cuan_app/pages/payments/premium_agreement_page.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:cuan_app/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  // GANTI ke link grup resmi kamu
  static final Uri _communityUri = Uri.parse('https://example.com/community');

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const _ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00A3A8), Color(0xFF006E72)],
  );

  Future<void> _openCommunityLink(BuildContext context) async {
    final ok = await canLaunchUrl(CommunityPage._communityUri);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan komunitas.')),
      );
      return;
    }
    await launchUrl(
      CommunityPage._communityUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchLink();
    });
  }

  void _showConfirmSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final p = context.read<CommunityProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(.5),
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
                        const SizedBox(height: 14),
                        Text(
                          'Anda akan diarahkan ke grup resmi di luar aplikasi.',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: .85),
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: "Lanjutkan",
                          gradient: _ctaGradient,
                          height: 50,
                          radius: 26,
                          shadow: true,
                          textStyle: tt.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await p.openLink(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  // tombol X di atas
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
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final p = context.watch<CommunityProvider>();
    final auth = context.watch<AuthProvider>();
    final me = auth.me;
    final isMember = me?.isMember == true;

    return Scaffold(
      appBar: AppBar(
        // leading: const BackButton(),
        title: const Text('Community'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SizedBox(height: 12),

          // Ilustrasi – ganti dengan asset sendiri jika ada
          Center(
            child: Image.asset(
              'assets/readme/community.png',
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),

          // Brand row
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 32,
                  child: Image.asset(
                    'assets/splash/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CUAN',
                      style: t.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00A3A8),
                        letterSpacing: .5,
                      ),
                    ),
                    Text(
                      'DIGITAL NUSANTARA',
                      style: t.textTheme.labelLarge?.copyWith(
                        color: cs.onSurface.withOpacity(.85),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          Text(
            'Mau dapet info terbaru biar cuan terus? 🪙\nJoin komunitas resmi sekarang, cukup Rp.[Nominal]!',
            textAlign: TextAlign.center,
            style: t.textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 24),
          if (p.error != null) ...[
            Text(
              p.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.error),
            ),
            const SizedBox(height: 8),
          ],
          // CTA
          if (isMember)
            _MembershipCard(memberUntil: me?.memberUntil)
          else
            GradientButton(
              label: p.loading ? "Memuat..." : "Join Sekarang!",
              gradient: _ctaGradient,
              height: 54,
              radius: 28,
              shadow: true,
              textStyle: t.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              onPressed: () async {
                final paid = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    // builder: (_) => const PaymentLauncherPage(),
                    builder: (_) => const PremiumAgreementPage(),
                  ),
                );
                if (!mounted) return;
                if (paid == true) {
                  await context.read<AuthProvider>().refreshMe();
                }
              },
            ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final dynamic memberUntil;
  const _MembershipCard({this.memberUntil});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    String subtitle = 'Akses komunitas premium sudah aktif';
    if (memberUntil != null) {
      subtitle = 'Membership aktif';
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(.35)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Membership Aktif',
                  style: t.textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
