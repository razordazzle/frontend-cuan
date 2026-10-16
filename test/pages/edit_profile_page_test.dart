import 'package:cuan_app/pages/menu/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ketikan user tidak ketimpa data lama saat keyboard muncul', (
    tester,
  ) async {
    // Avatar pakai NetworkImage; di test semua HTTP sengaja gagal (400). Abaikan error gambar saja.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.library == 'image resource service') return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: const RouteSettings(
            arguments: {'name': 'Albert', 'phone': '+62812345678910'},
          ),
          builder: (_) => const EditProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField).first;
    expect(find.text('Albert'), findsOneWidget);

    await tester.enterText(nameField, 'Alberta');
    // keyboard muncul -> MediaQuery berubah -> dulu didChangeDependencies isi ulang 'Albert'
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.text('Alberta'), findsOneWidget);
    expect(find.text('Albert'), findsNothing);
  });
}
