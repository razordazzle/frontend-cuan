import 'package:cuan_app/data/model/chart_payload.dart';
import 'package:cuan_app/data/services/auth_service.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:cuan_app/pages/screen/home_page.dart' show Ohlc;
import 'package:cuan_app/providers/stocks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStocksService implements StocksService {
  int calls = 0;
  Object? failWith;
  List<Ohlc> bars = const [];

  @override
  Future<ChartPayload> getIhsgChartWithIndicators({
    String interval = '1d',
    int limit = 60,
  }) async {
    calls++;
    if (failWith != null) throw failWith!;
    return ChartPayload(candles: List.of(bars));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Candle 1 menit hari ini (UTC; di WIB tanggalnya sama dengan UTC untuk jam 03:00-10:00 UTC).
List<Ohlc> _minutes(int count, {double base = 5140}) => List.generate(
  count,
  (i) => Ohlc(
    time: DateTime.utc(2026, 10, 29, 6, i),
    open: base,
    high: base + 1,
    low: base - 1,
    close: base + i,
    volume: 10,
  ),
);

void main() {
  late _FakeStocksService svc;
  late StocksProvider p;

  setUp(() {
    svc = _FakeStocksService()..bars = _minutes(5);
    p = StocksProvider(svc, _FakeAuthService());
  });

  test(
    'isIndexStale: belum pernah dimuat dianggap basi, sesudah dimuat segar',
    () async {
      expect(p.isIndexStale(const Duration(seconds: 60)), isTrue);
      await p.fetchIndexCandles();
      expect(p.isIndexStale(const Duration(seconds: 60)), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(p.isIndexStale(const Duration(milliseconds: 1)), isTrue);
    },
  );

  test('refreshIndexQuietly menambah candle baru TANPA spinner', () async {
    await p.fetchIndexCandles();
    expect(p.ihsgCandles.length, 5);

    final spinner = <bool>[];
    p.addListener(() => spinner.add(p.loadingIndex));
    svc.bars = _minutes(8); // 3 menit baru
    await p.refreshIndexQuietly();

    expect(p.ihsgCandles.length, 8);
    expect(p.ihsgChartPayload!.candles.length, 8);
    expect(spinner, isNotEmpty);
    expect(
      spinner.any((s) => s),
      isFalse,
      reason: 'loadingIndex tidak boleh menyala',
    );
    expect(p.errIndex, isNull);
  });

  test('refresh gagal: grafik lama tetap ada, tidak ada pesan error', () async {
    await p.fetchIndexCandles();
    svc.failWith = Exception('timeout');
    await p.refreshIndexQuietly();
    expect(p.ihsgCandles.length, 5);
    expect(p.errIndex, isNull);
    expect(p.loadingIndex, isFalse);
  });

  test(
    'di luar chip 1D tidak memanggil server (candle harian ke atas jarang berubah)',
    () async {
      await p.fetchIndexCandles();
      p.indexInterval = '1W';
      final before = svc.calls;
      await p.refreshIndexQuietly();
      expect(svc.calls, before);
    },
  );

  test(
    'fetchIndexCandles memakai data tersimpan kecuali dipaksa (perilaku lama tetap)',
    () async {
      await p.fetchIndexCandles();
      final after1 = svc.calls;
      await p.fetchIndexCandles();
      expect(svc.calls, after1);
      await p.fetchIndexCandles(force: true);
      expect(svc.calls, after1 + 1);
    },
  );
}
