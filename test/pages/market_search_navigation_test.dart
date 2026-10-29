import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/pages/screen/market_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mencatat nama rute di tumpukan (dari bawah ke atas) lewat NavigatorObserver.
class _StackObserver extends NavigatorObserver {
  final List<String> stack = [];
  String _n(Route<dynamic> r) => r.settings.name ?? '?';
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.add(_n(route));
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.remove(_n(route));
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.remove(_n(route));
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) stack.remove(_n(oldRoute));
    if (newRoute != null) stack.add(_n(newRoute));
  }
}

Route<void> _page(String name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

Future<(_StackObserver, GlobalKey<NavigatorState>)> _app(
  WidgetTester tester, {
  required String firstRoute,
}) async {
  final obs = _StackObserver();
  final key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: key,
      navigatorObservers: [obs],
      initialRoute: firstRoute,
      // satu rute saja (Flutter memecah '/main' jadi '/' + '/main'; di app asli splash diganti)
      onGenerateInitialRoutes: (name) => [_page(name)],
      onGenerateRoute: (s) => _page(s.name!),
    ),
  );
  await tester.pumpAndSettle();
  return (obs, key);
}

void main() {
  testWidgets(
    'dari detail: Home > BBCA > search > pilih BBRI -> tumpukan jadi Home > BBRI',
    (tester) async {
      final (obs, key) = await _app(tester, firstRoute: AppRoutes.main);
      key.currentState!.push(_page('BBCA'));
      await tester.pumpAndSettle();
      key.currentState!.push(_page('search'));
      await tester.pumpAndSettle();
      expect(obs.stack, [AppRoutes.main, 'BBCA', 'search']);

      pushStockFromSearch(key.currentContext!, _page('BBRI'), backToHome: true);
      await tester.pumpAndSettle();
      expect(obs.stack, [AppRoutes.main, 'BBRI']);

      key.currentState!.pop(); // back dari BBRI
      await tester.pumpAndSettle();
      expect(obs.stack, [AppRoutes.main]);
      expect(find.text(AppRoutes.main), findsOneWidget);
    },
  );

  testWidgets('search berulang dari detail tetap datar: back tetap ke Home', (
    tester,
  ) async {
    final (obs, key) = await _app(tester, firstRoute: AppRoutes.main);
    key.currentState!.push(_page('BBCA'));
    await tester.pumpAndSettle();
    for (final next in ['BBRI', 'GOTO', 'TLKM']) {
      key.currentState!.push(_page('search'));
      await tester.pumpAndSettle();
      pushStockFromSearch(key.currentContext!, _page(next), backToHome: true);
      await tester.pumpAndSettle();
      expect(obs.stack, [AppRoutes.main, next]);
    }
  });

  testWidgets(
    'dari Home (bukan dari detail): perilaku lama, search tetap di bawah detail',
    (tester) async {
      final (obs, key) = await _app(tester, firstRoute: AppRoutes.main);
      key.currentState!.push(_page('search'));
      await tester.pumpAndSettle();
      pushStockFromSearch(
        key.currentContext!,
        _page('BBCA'),
        backToHome: false,
      );
      await tester.pumpAndSettle();
      expect(obs.stack, [AppRoutes.main, 'search', 'BBCA']);
    },
  );

  testWidgets(
    'tanpa rute /main di tumpukan: rute pertama dipertahankan, tidak kosong',
    (tester) async {
      final (obs, key) = await _app(tester, firstRoute: '/lain');
      key.currentState!.push(_page('BBCA'));
      await tester.pumpAndSettle();
      key.currentState!.push(_page('search'));
      await tester.pumpAndSettle();
      pushStockFromSearch(key.currentContext!, _page('BBRI'), backToHome: true);
      await tester.pumpAndSettle();
      expect(obs.stack, ['/lain', 'BBRI']);
    },
  );

  testWidgets(
    'rute /main di tengah tumpukan (ada halaman di bawahnya) tetap jadi batas',
    (tester) async {
      final (obs, key) = await _app(tester, firstRoute: '/splash');
      key.currentState!.push(_page(AppRoutes.main));
      await tester.pumpAndSettle();
      key.currentState!.push(_page('BBCA'));
      await tester.pumpAndSettle();
      key.currentState!.push(_page('search'));
      await tester.pumpAndSettle();
      pushStockFromSearch(key.currentContext!, _page('BBRI'), backToHome: true);
      await tester.pumpAndSettle();
      expect(obs.stack, ['/splash', AppRoutes.main, 'BBRI']);
    },
  );
}
