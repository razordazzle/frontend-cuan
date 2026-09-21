import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/token_storage.dart';
import 'package:cuan_app/data/services/auth_service.dart';
import 'package:cuan_app/data/services/checkout_service.dart';
import 'package:cuan_app/data/services/community_service.dart';
import 'package:cuan_app/data/services/info_service.dart';
import 'package:cuan_app/data/services/journals_service.dart';
import 'package:cuan_app/data/services/qris_service.dart';
import 'package:cuan_app/data/services/search_service.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:cuan_app/data/services/vbl_service.dart';
import 'package:cuan_app/providers/auth_provider.dart';
import 'package:cuan_app/providers/community_provider.dart';
import 'package:cuan_app/providers/info_provider.dart';
import 'package:cuan_app/providers/journals_provider.dart';
import 'package:cuan_app/providers/market_provider.dart';
import 'package:cuan_app/providers/qris_provider.dart';
import 'package:cuan_app/providers/search_provider.dart';
import 'package:cuan_app/providers/stock_detail_provider.dart';
import 'package:cuan_app/providers/stocks_provider.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/styles/app_theme.dart';
import 'package:cuan_app/styles/theme_controller.dart';

void main() async {
  // ⬅️ pertahankan native splash sampai kita lepas manual di halaman animasi
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  TvChartWidget.preload();
  final theme = await ThemeController.load();
  final storage = TokenStorage();

  // Interceptor sederhana (refresh bisa null karena public endpoint)
  final infoInterceptor = AuthInterceptor(
    storage: storage,
    onRefresh: (_) async => null,
  );
  final stocksInterceptor = AuthInterceptor(
    storage: storage,
    onRefresh: (_) async =>
        null, // public endpoints mostly; sesuaikan jika perlu
  );
  // Satu interceptor untuk semua service (lebih konsisten)
  final sharedInterceptor = AuthInterceptor(
    storage: storage,
    // kalau nanti punya mekanisme refresh token, taruh di sini
    onRefresh: (_) async => null,
  );
  runApp(
    MultiProvider(
      providers: [
        // theme controller (ChangeNotifier)
        ChangeNotifierProvider.value(value: theme),

        // state auth
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),

        // expose interceptor & services
        Provider<AuthInterceptor>.value(value: sharedInterceptor),
        Provider<AuthService>(create: (_) => AuthService(storage)),
        Provider<InfoService>(
          create: (ctx) => InfoService(ctx.read<AuthInterceptor>()),
        ),
        Provider<StocksService>(
          create: (ctx) => StocksService(ctx.read<AuthInterceptor>()),
        ),
        Provider<VblService>(
          create: (ctx) => VblService(ctx.read<AuthInterceptor>()),
        ),
        // providers yang pakai services
        ChangeNotifierProvider(
          create: (ctx) => InfoProvider(ctx.read<InfoService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => StocksProvider(
            ctx.read<StocksService>(),
            ctx
                .read<
                  AuthService
                >(), // <-- injeksi AuthService utk add/remove watchlist
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => StockDetailProvider(ctx.read<StocksService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MarketProvider(ctx.read<StocksService>()),
        ),

        ChangeNotifierProvider(
          create: (ctx) => VblProvider(ctx.read<VblService>()),
        ),
        Provider<JournalsService>(
          create: (ctx) => JournalsService(ctx.read<AuthInterceptor>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => JournalsProvider(ctx.read<JournalsService>()),
        ),
        Provider<CommunityService>(
          create: (ctx) => CommunityService(ctx.read<AuthInterceptor>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CommunityProvider(ctx.read<CommunityService>()),
        ),
        Provider<SearchService>(
          create: (ctx) => SearchService(ctx.read<AuthInterceptor>()),
        ),
        ChangeNotifierProvider<SearchProvider>(
          create: (ctx) => SearchProvider(ctx.read<SearchService>()),
        ),
        Provider<QrisService>(
          create: (ctx) => QrisService(ctx.read<AuthInterceptor>()),
        ),
        Provider<CheckoutService>(
          create: (ctx) => CheckoutService(ctx.read<AuthInterceptor>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => QrisProvider(
            ctx.read<CheckoutService>(),
            ctx.read<QrisService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context
        .watch<ThemeController>()
        .mode; // rebuild saat theme ganti
    return MaterialApp(
      title: 'Cuan App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.pages, // settings route bisa const SettingsPage()
    );
  }
}
