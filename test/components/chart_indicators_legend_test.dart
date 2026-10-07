import 'package:cuan_app/components/chart_indicators_legend.dart';
import 'package:cuan_app/controllers/chart_indicators_controller.dart';
import 'package:cuan_app/data/model/active_chart_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Susunan Stack sama dengan halaman chart: overlay tap-outside muncul saat ada seleksi.
Widget _harness(ChartIndicatorsController controller) => MaterialApp(
  home: Scaffold(
    body: ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) => Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          if (controller.selectedId != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => controller.select(null),
              ),
            ),
          Positioned(
            key: const ValueKey<String>('indicators-legend'),
            top: 10,
            left: 10,
            right: 10,
            child: ChartIndicatorsLegend(
              controller: controller,
              symbol: 'BBCA',
              timeframe: '1D',
              onOpenSettings: (_) {},
            ),
          ),
        ],
      ),
    ),
  ),
);

/// Ikon di dalam modal Object tree (legend di belakangnya punya ikon yang sama).
Finder _inObjectTree(IconData icon) =>
    find.descendant(of: find.byType(ListView), matching: find.byIcon(icon));

/// Pilih indikator di legend lalu buka Object tree lewat menu ⋯.
Future<void> _openObjectTree(
  WidgetTester tester,
  ChartIndicatorsController controller,
) async {
  controller.select(controller.indicators.first.id);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.more_horiz_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Object tree...'));
  await tester.pumpAndSettle();
}

void main() {
  late ChartIndicatorsController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    controller = ChartIndicatorsController()
      ..add('rsi')
      ..add('macd');
  });

  tearDown(() => controller.dispose());

  testWidgets(
    'object tree: sekali tap mata langsung menyembunyikan indikator',
    (WidgetTester tester) async {
      await tester.pumpWidget(_harness(controller));
      await _openObjectTree(tester, controller);

      await tester.tap(_inObjectTree(Icons.visibility_outlined).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        controller.indicators.map((ActiveChartIndicator i) => i.isVisible),
        <bool>[true, false],
      );
      expect(_inObjectTree(Icons.visibility_off_outlined), findsOneWidget);
    },
  );

  testWidgets('object tree: hapus indikator tanpa error & daftar ikut update', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(controller));
    await _openObjectTree(tester, controller);

    await tester.tap(_inObjectTree(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.count, 1);
    expect(controller.indicators.single.type, 'macd');
    expect(find.text(controller.indicators.single.title), findsWidgets);
  });
}
