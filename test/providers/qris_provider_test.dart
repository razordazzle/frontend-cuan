import 'package:cuan_app/data/model/checkout_response.dart';
import 'package:cuan_app/data/model/qris_query_response.dart';
import 'package:cuan_app/data/services/checkout_service.dart';
import 'package:cuan_app/data/services/qris_service.dart';
import 'package:cuan_app/providers/qris_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

class _FakeCheckout implements CheckoutService {
  int n = 0;
  @override
  Future<CheckoutResponse> checkout({
    String? packageCode,
    String? journalId,
    int validTime = 9000,
    bool reuseIfPending = true,
  }) async {
    n++;
    return CheckoutResponse(
      ok: true,
      reusedInvoice: false,
      invoiceId: 'inv$n',
      invoiceNumber: 'INV-$n',
      amount: '501.00',
      paymentId: 'pay$n',
      partnerRefNo: 'ref$n',
      qrContent: 'qr',
    );
  }
}

/// Query palsu: butuh [latency] untuk menjawab, mencatat berapa yang berjalan bersamaan.
class _FakeQris implements QrisService {
  _FakeQris(this.latency, {this.paidAfterCalls = 1 << 30});
  final Duration latency;
  final int paidAfterCalls;
  int calls = 0;
  int running = 0;
  int maxRunning = 0;

  @override
  Future<QrisQueryResponse> query({required String partnerRefNo}) async {
    calls++;
    running++;
    if (running > maxRunning) maxRunning = running;
    await Future<void>.delayed(latency);
    running--;
    final paid = calls >= paidAfterCalls;
    return QrisQueryResponse(
      ok: true,
      partnerRefNo: partnerRefNo,
      latestStatus: paid ? '00' : null,
      isPaid: paid,
      status: paid ? 'paid' : 'pending',
    );
  }
}

void main() {
  test('gateway lambat: polling tidak menumpuk, hanya satu query berjalan', () {
    fakeAsync((async) {
      final qris = _FakeQris(const Duration(seconds: 12));
      final p = QrisProvider(_FakeCheckout(), qris);

      p.startCheckout(packageCode: 'WEEK');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));

      expect(qris.maxRunning, 1);
      // tick 5s (selesai 17s), tick 10 & 15s dilewati, tick 20s (selesai 32s)
      expect(qris.calls, 2);
      p.dispose();
    });
  });

  test('sudah dibayar: status paid dan polling berhenti', () {
    fakeAsync((async) {
      final qris = _FakeQris(const Duration(milliseconds: 100), paidAfterCalls: 2);
      final p = QrisProvider(_FakeCheckout(), qris);

      p.startCheckout(packageCode: 'WEEK');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));

      expect(p.paid, isTrue);
      expect(qris.calls, 2, reason: 'tidak ada query lagi setelah paid');
      p.dispose();
    });
  });

  test('hasil query checkout lama diabaikan kalau checkout baru sudah dimulai', () {
    fakeAsync((async) {
      final qris = _FakeQris(const Duration(seconds: 8), paidAfterCalls: 1);
      final p = QrisProvider(_FakeCheckout(), qris);

      p.startCheckout(packageCode: 'WEEK'); // ref1
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6)); // query ref1 sedang jalan (selesai di 13s)
      p.startCheckout(packageCode: 'WEEK'); // ref2 menggantikan
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5)); // 11s: query ref1 belum selesai

      async.elapse(const Duration(seconds: 3)); // 14s: query ref1 selesai dengan "paid"
      expect(p.current?.partnerRefNo, 'ref2');
      expect(p.paid, isFalse, reason: 'paid milik checkout lama tidak boleh menandai checkout baru');
      p.dispose();
    });
  });
}
