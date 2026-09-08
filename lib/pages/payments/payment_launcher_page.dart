import 'package:cuan_app/providers/qris_provider.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/data/model/payment_method.dart';
import 'package:cuan_app/pages/payments/payment_detail_page.dart';
import 'package:provider/provider.dart';

class PaymentLauncherPage extends StatefulWidget {
  const PaymentLauncherPage({super.key});

  @override
  State<PaymentLauncherPage> createState() => _PaymentLauncherPageState();
}

class _PaymentLauncherPageState extends State<PaymentLauncherPage> {
  bool _isLoading = false;
  bool _launched = false;
  // @override
  // didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (!_launched) {
  //     _launched = true;
  //     _startQrisFlow();
  //   }
  // }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_launched && mounted) {
        _launched = true;
        _startQrisFlow();
      }
    });
  }

  Future<void> _startQrisFlow() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      const packageCode = 'WEEK';

      const method = PaymentMethod(
        id: 'qris',
        label: 'QRIS',
        logoAsset: 'assets/payments/qris.png',
        group: PaymentGroup.qris,
      );

      await context.read<QrisProvider>().startCheckout(
        packageCode: packageCode,
      );

      if (!mounted) return;

      final q = context.read<QrisProvider>();

      if (q.current == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat invoice QRIS')),
        );
        Navigator.pop(context, false);
        return;
      }

      final amount = (double.tryParse(q.current?.amount ?? '0') ?? 0).round();

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => PaymentDetailPage(
      //       method: method,
      //       amount: amount,
      //       invoiceId: q.current?.invoiceId ?? '',
      //     ),
      //   ),
      // );
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentDetailPage(
            method: method,
            amount: amount,
            invoiceId: q.current?.invoiceId ?? '',
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, result ?? false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      Navigator.pop(context, false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget build(BuildContext context) {
    // TODO: ambil invoiceId dari server saat checkout
    // const invoiceId = 'YOUR_INVOICE_UUID_HERE';
    return Scaffold(
      appBar: AppBar(title: const Text('Menyiapkan Pembayaran')),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang menyiapkan QRIS...'),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
