import 'package:flutter/material.dart';
import 'package:cuan_app/pages/payments/payment_launcher_page.dart';

class PremiumAgreementPage extends StatefulWidget {
  const PremiumAgreementPage({super.key});

  @override
  State<PremiumAgreementPage> createState() => _PremiumAgreementPageState();
}

class _PremiumAgreementPageState extends State<PremiumAgreementPage> {
  bool _agreed = false;

  Future<void> _goToPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentLauncherPage(),
      ),
    );

    if (!mounted) return;

    // teruskan hasil ke halaman sebelumnya
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Membership'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 72,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Premium Community',
                      textAlign: TextAlign.center,
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sebelum melanjutkan pembayaran, mohon baca informasi berikut:',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    _InfoTile(
                      title: 'Akses membership',
                      description:
                          'Setelah pembayaran berhasil dan terverifikasi, akun Anda akan mendapatkan akses ke komunitas premium.',
                    ),
                    _InfoTile(
                      title: 'Metode pembayaran',
                      description:
                          'Pembayaran saat ini hanya tersedia melalui QRIS.',
                    ),
                    _InfoTile(
                      title: 'Proses verifikasi',
                      description:
                          'Status membership dapat membutuhkan beberapa saat untuk diperbarui setelah pembayaran berhasil.',
                    ),
                    _InfoTile(
                      title: 'Persetujuan',
                      description:
                          'Dengan melanjutkan, Anda menyetujui ketentuan membership yang berlaku di aplikasi ini.',
                    ),

                    const SizedBox(height: 20),

                    CheckboxListTile(
                      value: _agreed,
                      onChanged: (value) {
                        setState(() => _agreed = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Saya telah membaca dan menyetujui penjelasan di atas',
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _agreed ? _goToPayment : null,
                  child: const Text('Lanjut ke Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String description;

  const _InfoTile({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: t.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}