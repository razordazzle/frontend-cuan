import 'package:flutter/material.dart';

enum PaymentState { success, pending, failed }

class PaymentReceipt {
  const PaymentReceipt({
    required this.amount,
    required this.methodLabel, // e.g. BCA / BCA VA / OVO
    required this.status, // success / pending / failed
    required this.transTime, // DateTime transaksi
    required this.planTitle, // e.g. Reading Corner / Premium 30 Hari
    this.accountNumber, // tampil hanya untuk Bank/VA
    this.orderId, // optional: untuk referensi
  });

  final int amount;
  final String methodLabel;
  final PaymentState status;
  final DateTime transTime;
  final String planTitle;
  final String? accountNumber;
  final String? orderId;
}

class PaymentStatusPage extends StatelessWidget {
  const PaymentStatusPage({
    super.key,
    required this.receipt,
    this.onDone, // tekan “Selesai”
    this.titleOverride, // NEW
    this.subtitleOverride, // NEW
    this.primaryButtonLabel,
  });

  final PaymentReceipt receipt;
  final VoidCallback? onDone;

  final String? titleOverride;
  final String? subtitleOverride;
  final String? primaryButtonLabel;

  String _rupiah(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
    }
    return 'Rp ${buf.toString()}';
  }

  String _fmtDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final d = two(dt.day), m = two(dt.month), y = dt.year;
    final hh = two(dt.hour), mm = two(dt.minute), ss = two(dt.second);
    return '$m $d, $y, $hh:$mm:$ss';
  }

  (String, IconData, Color) _visual(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (receipt.status) {
      case PaymentState.success:
        return ('Payment Success!', Icons.check_circle_rounded, Colors.green);
      case PaymentState.pending:
        return ('Menunggu Pembayaran', Icons.schedule_rounded, Colors.amber);
      case PaymentState.failed:
        return ('Pembayaran Gagal', Icons.cancel_rounded, cs.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final (titleDefault, icon, base) = _visual(context);
    final isSuccess = receipt.status == PaymentState.success;

    final title = titleOverride ?? titleDefault;
    final subtitle =
        subtitleOverride ??
        (isSuccess
            ? 'Pembayaran berhasil! Akses premium telah aktif.'
            : (receipt.status == PaymentState.pending
                  ? 'Selesaikan pembayaran sebelum batas waktu.'
                  : 'Pembayaran gagal atau kadaluarsa. Silakan ulangi proses pembayaran.'));
    final ctaLabel =
        primaryButtonLabel ?? (isSuccess ? 'Selesai' : 'Coba Lagi');

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Status Pembayaran'),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // icon besar + heading
          Container(
            height: 124,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  base.withOpacity(.18),
                  base.withOpacity(.05),
                  Colors.transparent,
                ],
                stops: const [0.45, 0.75, 1.0],
              ),
            ),
            child: Icon(icon, size: 84, color: base),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.85)),
          ),
          const SizedBox(height: 16),

          // kartu ringkasan
          _ReceiptCard(
            amountText: _rupiah(receipt.amount),
            status: receipt.status,
            plan: receipt.planTitle,
            method: receipt.methodLabel,
            accountNumber: receipt.accountNumber,
            timeText: _fmtDateTime(receipt.transTime),
            orderId: receipt.orderId,
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onDone ?? () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/* ====================== UI bits ====================== */

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.amountText,
    required this.status,
    required this.plan,
    required this.method,
    required this.timeText,
    this.accountNumber,
    this.orderId,
  });

  final String amountText;
  final PaymentState status;
  final String plan;
  final String method;
  final String timeText;
  final String? accountNumber;
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    Color statusColor() {
      switch (status) {
        case PaymentState.success:
          return Colors.green;
        case PaymentState.pending:
          return Colors.amber;
        case PaymentState.failed:
          return cs.error;
      }
    }

    Widget row(String label, Widget value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: t.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            value,
          ],
        ),
      );
    }

    Widget valueText(String s, {bool bold = true}) => Text(
      s,
      textAlign: TextAlign.right,
      style: t.bodyMedium?.copyWith(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(.20)),
      ),
      child: Column(
        children: [
          row('Harga', valueText(amountText)),
          row(
            'Payment Status',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor().withOpacity(.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor().withOpacity(.45)),
              ),
              child: Text(
                status == PaymentState.success
                    ? 'Success'
                    : status == PaymentState.pending
                    ? 'Pending'
                    : 'Failed',
                style: t.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          if (accountNumber != null) row('No Rek', valueText(accountNumber!)),
          row('Metode Pembayaran', valueText(method)),
          row('Waktu Transaksi', valueText(timeText, bold: false)),
          row('Langganan yang dibeli', valueText(plan)),
          if (orderId != null)
            row('Order ID', valueText(orderId!, bold: false)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
