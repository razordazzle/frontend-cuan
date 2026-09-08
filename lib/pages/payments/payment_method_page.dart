import 'package:cuan_app/data/model/payment_method.dart';
import 'package:flutter/material.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key, this.onSelected});
  final ValueChanged<PaymentMethod>? onSelected;

  void _select(BuildContext context, PaymentMethod m) {
    onSelected?.call(m);            // opsional callback
    Navigator.pop(context, m);      // KEMBALIKAN PILIHAN KE CALLER
  }

  @override
  Widget build(BuildContext context) {

    // dummy data (ganti dari API)
    final va = const [
      PaymentMethod(
        id: 'bca_va',
        label: 'BCA VA',
        logoAsset: 'assets/payments/bca.png',
        group: PaymentGroup.virtualAccount,
      ),
    ];
    final bankTransfer = const [
      PaymentMethod(
        id: 'bca_transfer',
        label: 'BCA',
        logoAsset: 'assets/payments/bca.png',
        group: PaymentGroup.bankTransfer,
      ),
      PaymentMethod(
        id: 'mandiri_transfer',
        label: 'MANDIRI',
        logoAsset: 'assets/payments/mandiri.png',
        group: PaymentGroup.bankTransfer,
      ),
    ];
    final ewallet = const [
      PaymentMethod(
        id: 'dana',
        label: 'DANA',
        logoAsset: 'assets/payments/dana.png',
        group: PaymentGroup.ewallet,
      ),
      PaymentMethod(
        id: 'ovo',
        label: 'OVO',
        logoAsset: 'assets/payments/ovo.png',
        group: PaymentGroup.ewallet,
      ),
      PaymentMethod(
        id: 'gopay',
        label: 'GOPAY',
        logoAsset: 'assets/payments/gopay.png',
        group: PaymentGroup.ewallet,
      ),
    ];
    final qris = const [
      PaymentMethod(
        id: 'qris',
        label: 'QRIS',
        logoAsset: 'assets/payments/qris.png',
        group: PaymentGroup.qris,
      ),
    ];

    return Scaffold(
      appBar: const _PMAppBar(),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16, 16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            const _SectionTitle('Virtual ', trailingBold: 'Account'),
            for (final m in va) _MethodTile(method: m, onTap: () => _select(context, m)),
            const SizedBox(height: 20),

            const _SectionTitle('Transfer ', trailingBold: 'Bank'),
            for (final m in bankTransfer) _MethodTile(method: m, onTap: () => _select(context, m)),
            const SizedBox(height: 20),

            const _SectionTitle('E–', trailingBold: 'Wallet'),
            for (final m in ewallet) _MethodTile(method: m, onTap: () => _select(context, m)),
            const SizedBox(height: 20),

            const _SectionTitle('Qris'),
            for (final m in qris) _MethodTile(method: m, onTap: () => _select(context, m)),
          ],
        ),
      ),
    );
  }
}

/* ---- UI bits sama seperti punyamu ---- */
class _PMAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PMAppBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: const Text('Pilih Metode Pembayaran'),
    leading: const BackButton(),
    centerTitle: false,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailingBold});
  final String text; final String? trailingBold;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: RichText(
        text: TextSpan(
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, color: cs.onBackground, height: 1.2,
          ),
          children: [
            TextSpan(text: text),
            if (trailingBold != null)
              TextSpan(text: trailingBold!, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.onTap, this.disabled = false});
  final PaymentMethod method; final VoidCallback? onTap; final bool disabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final enabled = onTap != null && !disabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 60,
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withOpacity(.25), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                _LogoBox(asset: method.logoAsset),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    method.label,
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: enabled ? cs.onSurface : cs.onSurface.withOpacity(.4),
                      letterSpacing: .2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(.5)),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox({required this.asset});
  final String asset;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 36, height: 36, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withOpacity(.15)),
      ),
      child: Image.asset(
        asset, height: 22, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: 18, color: cs.primary),
      ),
    );
  }
}
