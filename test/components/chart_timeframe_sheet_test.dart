import 'package:cuan_app/components/chart_timeframe_sheet.dart';
import 'package:cuan_app/data/model/chart_timeframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sheet menampilkan semua timeframe per kelompok & mengembalikan pilihan',
    (WidgetTester tester) async {
      // Layar tinggi supaya semua item ListView (lazy) ikut dirender.
      tester.view.physicalSize = const Size(1200, 3600);
      addTearDown(tester.view.reset);
      ChartTimeframe? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async => result = await ChartTimeframeSheet.show(
                context: context,
                selected: ChartTimeframe.day1,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (final ChartTimeframeGroup group in ChartTimeframeGroup.values) {
        expect(find.text(group.title), findsOneWidget);
      }
      for (final ChartTimeframe timeframe in ChartTimeframe.values) {
        expect(find.text(timeframe.title), findsOneWidget);
      }

      await tester.tap(find.text(ChartTimeframe.minute15.title));
      await tester.pumpAndSettle();
      expect(result, ChartTimeframe.minute15);
    },
  );
}
