import 'package:cuan_app/components/drawing_tools.dart';
import 'package:cuan_app/components/indicator_settings_sheet.dart';
import 'package:cuan_app/components/indicators_modal_sheet.dart';
import 'package:cuan_app/controllers/chart_drawings_controller.dart';
import 'package:cuan_app/controllers/chart_indicators_controller.dart';
import 'package:cuan_app/data/model/active_chart_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sheet & modal chart dirender tanpa error layout. Error seperti "Incorrect use of
/// ParentDataWidget" hanya muncul di log saat debug, tapi di build release tampil
/// sebagai lapisan abu-abu, jadi harus ditangkap lewat test.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> pumpSheet(WidgetTester tester, Widget sheet) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // Font test (Ahem) selebar 1em per huruf, ~2x font asli; diskalakan supaya
        // overflow yang terdeteksi benar-benar terjadi di HP, bukan efek font test.
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.6)),
          child: child!,
        ),
        home: Scaffold(body: sheet),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('sheet indikator', (WidgetTester tester) async {
    await pumpSheet(
      tester,
      IndicatorsModalSheet(
        favoriteIndicators: const <String>{},
        onToggleFavorite: (_) {},
        onAddIndicator: (_) {},
      ),
    );
  });

  testWidgets('sheet drawing tools', (WidgetTester tester) async {
    final ChartDrawingsController controller = ChartDrawingsController();
    addTearDown(controller.dispose);
    await pumpSheet(tester, DrawingToolsSheet(controller: controller));
  });

  for (final String type in <String>['sma', 'rsi', 'vol', 'macd']) {
    testWidgets('modal settings $type (tab Inputs & Style)', (
      WidgetTester tester,
    ) async {
      final ChartIndicatorsController controller = ChartIndicatorsController()
        ..add(type);
      addTearDown(controller.dispose);
      final ActiveChartIndicator indicator = controller.indicators.single;
      await pumpSheet(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showIndicatorSettingsSheet(
              context: context,
              indicator: indicator,
              onSave: (_) {},
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Style'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
