import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cuan_app/components/default_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gambar [DefaultAvatar] berjari-jari 100 di atas latar merah (supaya sisi luar lingkaran
/// terlihat berbeda dari warna avatar) dan kembalikan fungsi pembaca piksel.
Future<List<int> Function(int x, int y)> _render(
  WidgetTester tester, {
  Widget avatar = const DefaultAvatar(radius: 100),
}) async {
  final key = GlobalKey();
  await tester.binding.setSurfaceSize(const Size(200, 200));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: Container(color: const Color(0xFFFF0000), child: avatar),
      ),
    ),
  );
  late ByteData data;
  late int w;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    w = image.width;
    data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  });
  return (x, y) {
    final i = (y * w + x) * 4;
    return [data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2)];
  };
}

void main() {
  const gray = [221, 225, 226];
  const white = [255, 255, 255];
  const red = [255, 0, 0];

  testWidgets(
    'bentuk: abu-abu, kepala putih, celah leher abu-abu, bahu putih',
    (tester) async {
      final px = await _render(tester);
      expect(px(100, 15), gray, reason: 'pita abu-abu di atas kepala');
      expect(px(100, 70), white, reason: 'pusat kepala');
      expect(px(100, 113), gray, reason: 'celah antara kepala dan bahu');
      expect(px(100, 150), white, reason: 'kubah bahu');
      expect(px(20, 100), gray, reason: 'sisi kiri lingkaran');
      expect(px(180, 100), gray, reason: 'sisi kanan lingkaran');
    },
  );

  testWidgets('berbentuk lingkaran: sudut kotak tidak ikut digambar', (
    tester,
  ) async {
    final px = await _render(tester);
    expect(px(2, 2), red);
    expect(px(197, 2), red);
    expect(px(2, 197), red);
    expect(px(197, 197), red);
  });

  testWidgets('ukuran mengikuti radius (seperti CircleAvatar)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: DefaultAvatar(radius: 36))),
    );
    expect(tester.getSize(find.byType(DefaultAvatar)), const Size(72, 72));
  });

  testWidgets('warna bisa diganti', (tester) async {
    final px = await _render(
      tester,
      avatar: const DefaultAvatar(
        radius: 100,
        background: Color(0xFF0000FF),
        foreground: Color(0xFF00FF00),
      ),
    );
    expect(px(100, 15), [0, 0, 255]);
    expect(px(100, 70), [0, 255, 0]);
  });
}
