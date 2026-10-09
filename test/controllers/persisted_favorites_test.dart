import 'package:cuan_app/controllers/chart_drawings_controller.dart';
import 'package:cuan_app/controllers/chart_indicators_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tunggu load/save SharedPreferences (mock) yang berjalan async selesai.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('default favorit kosong', () {
    final ChartDrawingsController drawings = ChartDrawingsController();
    final ChartIndicatorsController indicators = ChartIndicatorsController();
    expect(drawings.favoriteTools, isEmpty);
    expect(indicators.favorites, isEmpty);
    drawings.dispose();
    indicators.dispose();
  });

  test('favorit drawing tetap ada saat controller dibuat ulang', () async {
    final ChartDrawingsController first = ChartDrawingsController();
    await _flush();
    first.toggleFavorite(ChartDrawingTool.trendline);
    first.dispose();
    await _flush();

    final ChartDrawingsController second = ChartDrawingsController();
    int notifications = 0;
    second.addListener(() => notifications++);
    await _flush();

    expect(second.favoriteTools, <ChartDrawingTool>[
      ChartDrawingTool.trendline,
    ]);
    expect(notifications, 1, reason: 'toolbar harus rebuild setelah dimuat');
    second.dispose();
  });

  test('favorit indikator tetap ada saat controller dibuat ulang', () async {
    final ChartIndicatorsController first = ChartIndicatorsController();
    await _flush();
    first
      ..toggleFavorite('Volume')
      ..toggleFavorite('Moving Average Convergence Divergence');
    first.dispose();
    await _flush();

    final ChartIndicatorsController second = ChartIndicatorsController();
    await _flush();
    expect(second.favorites, <String>[
      'Volume',
      'Moving Average Convergence Divergence',
    ]);
    second.dispose();
  });

  test('perubahan sebelum data selesai dimuat tidak tertimpa', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chart.drawingFavorites': <String>['fibonacci'],
    });
    final ChartDrawingsController controller = ChartDrawingsController()
      ..toggleFavorite(ChartDrawingTool.rectangle); // sebelum load selesai
    await _flush();

    expect(controller.favoriteTools, <ChartDrawingTool>[
      ChartDrawingTool.rectangle,
    ]);
    controller.dispose();
  });
}
