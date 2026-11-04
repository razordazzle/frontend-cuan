import 'package:cuan_app/controllers/chart_drawings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, dynamic> _wave = <String, dynamic>{
  'id': 'wave_1',
  'kind': 'elliottCorrection',
};

void main() {
  late ChartDrawingsController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    controller = ChartDrawingsController();
  });

  tearDown(() => controller.dispose());

  test('hanya Path & Elliott Wave yang termasuk wave', () {
    expect(
      ChartDrawingTool.values.where((ChartDrawingTool t) => t.isWave),
      <ChartDrawingTool>[
        ChartDrawingTool.path,
        ChartDrawingTool.elliottImpulse,
        ChartDrawingTool.elliottCorrection,
        ChartDrawingTool.elliottTriangle,
      ],
    );
  });

  test('drawingWave hanya terisi saat tool aktif adalah wave', () {
    controller.startDrawing(ChartDrawingTool.trendline);
    expect(controller.drawingWave, isNull);

    controller.startDrawing(ChartDrawingTool.elliottImpulse);
    expect(controller.drawingWave, ChartDrawingTool.elliottImpulse);
  });

  test('wave dari chart mengakhiri mode gambar wave', () {
    controller.startDrawing(ChartDrawingTool.path);
    controller.setWaves(<Map<String, dynamic>>[_wave]);

    expect(controller.isDrawingAny, isFalse);
    expect(controller.waves, <Map<String, dynamic>>[_wave]);
    expect(controller.hasDrawings, isTrue);
  });

  test('perubahan wave tidak mengakhiri tool lain yang sedang aktif', () {
    controller.startDrawing(ChartDrawingTool.rectangle);
    controller.setWaves(<Map<String, dynamic>>[_wave]);

    expect(controller.isDrawing(ChartDrawingTool.rectangle), isTrue);
  });

  test('clearAll ikut menghapus wave', () {
    controller.setWaves(<Map<String, dynamic>>[_wave]);
    controller.clearAll();

    expect(controller.waves, isEmpty);
    expect(controller.hasDrawings, isFalse);
  });
}
