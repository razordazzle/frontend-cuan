import 'package:cuan_app/components/bottom_navigation_item.dart';
import 'package:cuan_app/pages/screen/community_page.dart';
import 'package:cuan_app/pages/screen/home_page.dart';
import 'package:cuan_app/pages/screen/market_page.dart';
import 'package:cuan_app/pages/screen/modul_page.dart';
import 'package:cuan_app/pages/screen/research_page.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/config/app_routes.dart';

// TODO: ganti dengan page benerannya kalau sudah ada
// import 'package:cuan_app/pages/home_page.dart';      // stub / halamanmu
// import 'package:cuan_app/pages/market_page.dart';    // stub / halamanmu
// import 'package:cuan_app/pages/modal_page.dart';     // stub / halamanmu
// import 'package:cuan_app/pages/news_page.dart';      // stub / halamanmu
// import 'package:cuan_app/pages/research_page.dart';  // stub / halamanmu
// import 'package:cuan_app/pages/course_page.dart';    // stub / halamanmu

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  late final List<Widget> _pages = const [
    HomePage(),
    MarketPage(), // MarketPage()
    ModulPage(), // ModalPage()
    ResearchPage(), // ResearchPage()
    CommunityPage(), // CommunityPage()
  ];

  static const _items = <NavItem>[
    NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    NavItem(
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      label: 'Market',
    ),
    NavItem(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Modul',
    ),

    NavItem(
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      label: 'Research',
    ),
    NavItem(
      icon: Icons.people,
      selectedIcon: Icons.article,
      label: 'Community',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: CuanNavigationBar(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        // labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // opsional
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w500,
        ),
        iconSize: 22,
        textScaleFactor: 0.95, // sedikit kecil agar tidak wrap di device kecil
      ),
      extendBody: true,
    );
  }
}
