import 'package:cuan_app/pages/payments/payment_status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('label struk tetap 1 baris di HP sempit walau Order ID panjang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentStatusPage(
          receipt: PaymentReceipt(
            amount: 501,
            methodLabel: 'QRIS',
            status: PaymentState.success,
            transTime: DateTime(2026, 10, 16, 10, 30),
            planTitle: 'Analisis Fundamental Saham Perbankan Kuartal III 2026',
            itemLabel: 'Journal yang dibeli',
            orderId: 'd6fee3e8-f811-4b17-8b21-ee83be6b8dbd',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // tidak ada overflow
    final oneLine = tester.getSize(find.text('Harga')).height;
    expect(tester.getSize(find.text('Order ID')).height, oneLine);
    // nilai panjang boleh turun baris, tapi tetap tampil utuh
    expect(find.text('d6fee3e8-f811-4b17-8b21-ee83be6b8dbd'), findsOneWidget);
    // format waktu transaksi: singkatan bulan Indonesia
    expect(find.text('Okt 16, 2026, 10:30:00'), findsOneWidget);
  });
}
