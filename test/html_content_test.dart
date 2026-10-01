import 'package:cuan_app/components/html_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// PNG 2000x40 (jauh lebih lebar dari layar HP) untuk menguji gambar tidak meluber.
const String _widePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAB9AAAAAoCAIAAAApPPbUAAABRElEQVR42u3YMQ0AAAzDsKIpf0ADMwg79loygpzJtAAAAAAAwFMkAAAAAAAAwx0AAAAAAAx3AAAAAAAw3AEAAAAAAMMdAAAAAAAMdwAAAAAAMNwBAAAAAMBwBwAAAAAADHcAAAAAADDcAQAAAADAcAcAAAAAAMMdAAAAAAAw3AEAAAAAwHAHAAAAAADDHQAAAAAADHcAAAAAAMBwBwAAAAAAwx0AAAAAAAx3AAAAAAAw3AEAAAAAAMMdAAAAAAAMdwAAAAAAMNwBAAAAAMBwBwAAAAAADHcAAAAAADDcAQAAAADAcAcAAAAAAAx3AAAAAAAw3AEAAAAAwHAHAAAAAADDHQAAAAAAMNwBAAAAAMBwBwAAAAAAwx0AAAAAAAx3AAAAAADAcAcAAAAAAMMdAAAAAAAMdwAAAAAAMNwBAAAAAIDLAotlaSiubLF6AAAAAElFTkSuQmCC';

// Bentuk HTML yang dihasilkan RichTextEditor admin (setelah disaring backend).
const String _editorHtml =
    '<h2>Judul Laporan</h2>'
    '<div style="text-align:center"><b>Tebal</b> <i>miring</i> <u>garis</u> '
    '<font color="#ef4444">merah</font> '
    '<span style="font-size:24px;background-color:rgb(253, 224, 71)">besar</span></div>'
    '<ul><li>satu</li><li>dua</li></ul>'
    '<blockquote>kutipan</blockquote><pre>kode</pre>'
    '<a href="https://cuandiara.com">tautan</a>';

Future<void> _pumpWidget(WidgetTester tester, Widget child, {double width = 360}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

Future<void> _pump(WidgetTester tester, String html) =>
    _pumpWidget(tester, HtmlContent(html: html));

void main() {
  group('HtmlContent.toHtml', () {
    test('teks polos: baris baru jadi <br>', () {
      expect(HtmlContent.toHtml('baris satu\nbaris dua'), 'baris satu<br>baris dua');
    });

    test('HTML dibiarkan apa adanya', () {
      expect(HtmlContent.toHtml(_editorHtml), _editorHtml);
    });

    test('teks yang sudah di-escape server tidak di-escape dua kali', () {
      expect(HtmlContent.toHtml('Laba &amp; rugi'), 'Laba &amp; rugi');
    });
  });

  test('plainText membuang tag', () {
    expect(HtmlContent.plainText('<p>Halo <b>dunia</b></p>'), 'Halo  dunia');
  });

  test('isLaunchable hanya mengizinkan http, https, mailto', () {
    expect(HtmlContent.isLaunchable('https://cuandiara.com'), isTrue);
    expect(HtmlContent.isLaunchable('http://cuandiara.com'), isTrue);
    expect(HtmlContent.isLaunchable('mailto:cs@cuandiara.com'), isTrue);
    expect(HtmlContent.isLaunchable('javascript:alert(1)'), isFalse);
    expect(HtmlContent.isLaunchable('intent://x#Intent;end'), isFalse);
    expect(HtmlContent.isLaunchable('/relatif/saja'), isFalse);
    expect(HtmlContent.isLaunchable(null), isFalse);
  });

  group('render', () {
    testWidgets('HTML dari editor tampil tanpa error layout di layar sempit', (tester) async {
      await _pump(tester, _editorHtml);

      expect(tester.takeException(), isNull);
      for (final text in ['Judul Laporan', 'Tebal', 'merah', 'besar', 'satu', 'dua', 'kutipan', 'kode', 'tautan']) {
        expect(find.textContaining(text, findRichText: true), findsWidgets, reason: text);
      }
    });

    testWidgets('tag HTML tidak bocor sebagai teks', (tester) async {
      await _pump(tester, _editorHtml);

      expect(find.textContaining('<b>', findRichText: true), findsNothing);
      expect(find.textContaining('<font', findRichText: true), findsNothing);
    });

    testWidgets('teks polos multi-baris tampil sebagai dua baris', (tester) async {
      await _pump(tester, 'baris satu\nbaris dua');

      expect(tester.takeException(), isNull);
      final text = tester.widgetList<RichText>(find.byType(RichText)).map((w) => w.text.toPlainText()).join('|');
      expect(text, contains('baris satu'));
      expect(text, contains('baris dua'));
      expect(text, contains('\n'));
    });

    testWidgets('teaser: isi panjang memudar lewat ShaderMask', (tester) async {
      final longHtml = '<p>${'kalimat panjang untuk pratinjau premium ' * 10}</p>';
      await _pumpWidget(tester, HtmlTeaser(html: longHtml, clearRatio: 0.35));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.textContaining('kalimat panjang', findRichText: true), findsWidgets);
    });

    testWidgets('teaser: isi pendek tampil utuh tanpa pudar', (tester) async {
      await _pumpWidget(tester, HtmlTeaser(html: '<p>singkat</p>', clearRatio: 0.35));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.textContaining('singkat', findRichText: true), findsOneWidget);
    });

    testWidgets('gambar lebar tidak melebihi lebar layar', (tester) async {
      await _pump(tester, '<p>sebelum</p><img src="data:image/png;base64,$_widePngBase64"><p>sesudah</p>');

      expect(tester.takeException(), isNull);
      final image = find.byType(Image);
      expect(image, findsOneWidget);
      expect(tester.getSize(image).width, lessThanOrEqualTo(360));
    });
  });
}
