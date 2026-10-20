import 'package:cuan_app/pages/launch/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('halaman Lupa Password sesuai desain & email dari login terisi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordPage(initialEmail: 'albert@example.com'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lupa Password'), findsOneWidget);
    expect(find.text('Masukan email Anda'), findsOneWidget);
    expect(find.text('Kirim'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.text('albert@example.com'), findsOneWidget);
  });

  testWidgets('email kosong / tidak valid ditolak sebelum tanya server', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();
    expect(find.text('Wajib diisi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'bukan-email');
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak valid'), findsOneWidget);
  });

  testWidgets('pop-up konfirmasi tampil & tombol X menutupnya', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showForgotPasswordConfirm(context, 'a@b.com'),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('mengatur ulang password Anda?'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Ya, saya setuju'), findsNothing);
  });

  testWidgets(
    'halaman berhasil: tombol Kembali kembali ke halaman sebelumnya',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordSentPage(),
                  ),
                ),
                child: const Text('Halaman Login'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Halaman Login'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Pengaturan ulang password berhasil dilakukan'),
        findsOneWidget,
      );
      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman Login'), findsOneWidget);
    },
  );
}
