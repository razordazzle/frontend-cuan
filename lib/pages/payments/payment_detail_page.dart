// payment_detail_page.dart
import 'dart:async';
import 'dart:ui' show FontFeature; // <-- penting utk TextStyle.fontFeatures
import 'package:cuan_app/data/model/payment_method.dart';
import 'package:cuan_app/pages/payments/payment_status_page.dart';
import 'package:cuan_app/providers/qris_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Halaman detail pembayaran.
/// - Jika [method.group] == PaymentGroup.qris → layout QRIS.
/// - Selain itu → layout Bank/VA/E-Wallet.
class PaymentDetailPage extends StatefulWidget {
  const PaymentDetailPage({
    super.key,
    required this.method,
    required this.invoiceId,
    this.amount = 100000,
    this.accountNumber, // wajib untuk Bank/VA
    this.timeLimit = const Duration(minutes: 20, seconds: 20),
  });

  final PaymentMethod method;
  final String invoiceId;
  final int amount;
  final String? accountNumber;
  final Duration timeLimit;

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  late DateTime _endAt;
  Timer? _timer;
  Duration _remain = Duration.zero;
  bool _handledSuccess = false;

  @override
  void initState() {
    super.initState();

    // Safety: untuk Bank/VA pastikan ada accountNumber
    // assert(
    //   widget.method.group != PaymentGroup.bankTransfer &&
    //           widget.method.group != PaymentGroup.virtualAccount ||
    //       widget.accountNumber != null,
    //   'accountNumber wajib diisi untuk Bank/VA',
    // );

    _endAt = DateTime.now().add(widget.timeLimit);
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Kalau user masuk ke detail tanpa lewat launcher (direct open),

    // ✅ Jangan panggil startPayment / generate lagi di sini.
    // QR sudah dibuat dari PaymentLauncherPage via startCheckout().
  }

  Future<void> _handlePaid() async {
    if (_handledSuccess || !mounted) return;
    _handledSuccess = true;

    await context.read<QrisProvider>().stopPolling();

    if (!mounted) return;
    // Navigator.pop(context, true);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
          receipt: PaymentReceipt(
            amount: widget.amount,
            methodLabel: widget.method.label,
            status: PaymentState.success,
            transTime: DateTime.now(),
            planTitle: 'Reading Corner',
            orderId: widget.invoiceId,
          ),
        ),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, result ?? true);
  }

  void _tick() {
    final left = _endAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _remain = left.isNegative ? Duration.zero : left);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _remainText {
    final h = _remain.inHours;
    final m = _remain.inMinutes.remainder(60);
    final s = _remain.inSeconds.remainder(60);
    if (h > 0) return '${_two(h)}:${_two(m)}:${_two(s)}';
    return '${_two(m)}:${_two(s)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

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

  void _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disalin ke papan klip')));
  }

  // void _goSuccess(BuildContext context) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => PaymentStatusPage(
  //         receipt: PaymentReceipt(
  //           amount: widget.amount,
  //           methodLabel: widget.method.label,
  //           status: PaymentState.success,
  //           transTime: DateTime.now(),
  //           planTitle: 'Reading Corner',
  //           orderId: widget.invoiceId,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final header = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outline.withOpacity(.15)),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            widget.method.logoAsset,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.account_balance_wallet, color: cs.primary, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          widget.method.label,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
    final q = context.watch<QrisProvider>();
    final isQris = widget.method.group == PaymentGroup.qris;

    // Auto redirect kalau paid
    // if (isQris) {
    //   final q = context.watch<QrisProvider>();
    //   if (q.paid) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) async {
    //       if (!mounted) return;
    //       await context.read<QrisProvider>().stopPolling();
    //       _goSuccess(context);
    //     });
    //   }
    // }
    if (isQris && q.paid && !_handledSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePaid();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.method.label),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          header,
          const SizedBox(height: 16),

          if (isQris)
            _QrisSection(
              amountText: _rupiah(widget.amount),
              remainText: _remainText,
              onPaid: () => context.read<QrisProvider>().refreshOnce(),
            )
          else
            _BankSection(
              amountText: _rupiah(widget.amount),
              remainText: _remainText,
              accountNumber: widget.accountNumber ?? '0000000000',
              onCopy: _copy,
              onPayNow: () {
                // TODO: cek invoice ke server
              },
            ),
        ],
      ),
    );
  }
}

/* ================= QRIS ================= */

class _QrisSection extends StatelessWidget {
  const _QrisSection({
    required this.amountText,
    required this.remainText,
    // required this.onDownload,
    required this.onPaid,
    // required this.onFailed,
  });

  final String amountText;
  final String remainText;
  // final VoidCallback onDownload;
  final VoidCallback onPaid;
  // final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final q = context.watch<QrisProvider>();

    Widget label(String s) => Text(
      s,
      style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.75)),
    );

    Widget field(String value) => _FieldShell(
      child: Text(
        value,
        style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    final qrContent = q.current?.qrContent ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // QR Preview
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withOpacity(.12)),
            ),
            alignment: Alignment.center,
            child: q.loading
                ? const CircularProgressIndicator()
                : (q.error != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            q.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black),
                          ),
                        )
                      : (qrContent.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'QR belum tersedia. Silakan ulangi checkout.',
                                  style: TextStyle(color: Colors.black),
                                ),
                              )
                            : QrImageView(
                                data: qrContent,
                                version: QrVersions.auto,
                                size: 180,
                                backgroundColor: Colors
                                    .white, // ✅ 2. Latar belakang QR putih
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black, // ✅ 3. Mata QR hitam
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors
                                      .black, // ✅ 4. Titik-titik data QR hitam
                                ),
                              ))),
          ),
        ),
        const SizedBox(height: 12),

        // Baris timer + download
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label('Bayar Sebelum'),
                  const SizedBox(height: 4),
                  Text(
                    remainText,
                    style: t.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        label('Total yang harus dibayar'),
        const SizedBox(height: 6),
        field(amountText),
        const SizedBox(height: 14),

        label('Status Pembayaran'),
        const SizedBox(height: 6),
        _StatusChip(
          text: q.statusText,
          color: q.paid ? Colors.green : Colors.amber,
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onPaid,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Saya sudah bayar'),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Panduan Penyetoran',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const _Bullet('Buka aplikasi dompet/bank yang mendukung QRIS.'),
        const _Bullet(
          'Arahkan kamera ke QR Code di atas hingga muncul halaman pembayaran.',
        ),
        const _Bullet('Anda juga bisa mengunggah kode QR dari galeri.'),
      ],
    );
  }
}

/* ================= BANK / VA / E-WALLET ================= */

class _BankSection extends StatelessWidget {
  const _BankSection({
    required this.amountText,
    required this.remainText,
    required this.accountNumber,
    required this.onCopy,
    required this.onPayNow,
  });

  final String amountText;
  final String remainText;
  final String accountNumber;
  final void Function(String) onCopy;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    Widget label(String s) => Text(
      s,
      style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.75)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris "Bayar Sebelum" + timer
        Row(
          children: [
            Expanded(child: label('Bayar Sebelum')),
            Text(
              remainText,
              style: t.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        label('No Rekening'),
        const SizedBox(height: 6),
        _FieldShell(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  accountNumber,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Salin',
                onPressed: () => onCopy(accountNumber),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        label('Total yang harus dibayar'),
        const SizedBox(height: 6),
        _FieldShell(
          child: Text(
            amountText,
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),

        label('Status Pembayaran'),
        const SizedBox(height: 6),
        const _StatusChip(text: 'Menunggu Pembayaran', color: Colors.amber),
        const SizedBox(height: 18),

        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onPayNow,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Bayar Sekarang'),
          ),
        ),
      ],
    );
  }
}

/* ================= Small Reusable ================= */

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(.25)),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = color ?? Colors.amber;
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: base.withOpacity(.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.withOpacity(.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: BoxDecoration(
              color: cs.onSurface,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: t.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
