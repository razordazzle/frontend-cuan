import '../data/model/chart_payload.dart';
import '../data/model/chart_timeframe.dart';

/// Cache payload chart per timeframe untuk satu simbol (di memori).
///
/// Kembali ke timeframe yang sudah dibuka langsung tampil tanpa request ke backend.
/// Hanya satu simbol yang disimpan: ganti simbol mengosongkan cache supaya memori tidak
/// menumpuk. Umur entri mengikuti cache backend (intraday 60 detik, harian ke atas
/// 10 menit); candle terakhir tetap bergerak dari harga live WebSocket.
class ChartPayloadCache {
  ChartPayloadCache({DateTime Function() clock = DateTime.now}) : _now = clock;

  static const Duration _intradayTtl = Duration(seconds: 60);
  static const Duration _dailyTtl = Duration(minutes: 10);

  final DateTime Function() _now;
  final Map<ChartTimeframe, _CachedPayload> _entries =
      <ChartTimeframe, _CachedPayload>{};
  String? _symbol;

  /// Payload yang masih segar, atau null kalau belum ada / sudah kedaluwarsa.
  ChartPayload? get(String symbol, ChartTimeframe timeframe) {
    if (symbol != _symbol) return null;
    final _CachedPayload? entry = _entries[timeframe];
    if (entry == null || !_now().isBefore(entry.expiresAt)) return null;
    return entry.payload;
  }

  void put(String symbol, ChartTimeframe timeframe, ChartPayload payload) {
    if (symbol != _symbol) {
      _entries.clear();
      _symbol = symbol;
    }
    // Payload kosong tidak disimpan supaya buka berikutnya mencoba backend lagi.
    if (payload.candles.isEmpty) return;
    _entries[timeframe] = _CachedPayload(payload, _now().add(_ttl(timeframe)));
  }

  static Duration _ttl(ChartTimeframe timeframe) =>
      timeframe.group == ChartTimeframeGroup.days ? _dailyTtl : _intradayTtl;
}

class _CachedPayload {
  const _CachedPayload(this.payload, this.expiresAt);

  final ChartPayload payload;
  final DateTime expiresAt;
}
