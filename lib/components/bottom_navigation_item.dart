// lib/components/navigation_bar_item.dart
import 'package:flutter/material.dart';

/// Data tiap item di NavigationBar
class NavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  /// Tampilkan badge angka (mis. notifikasi). Null = tak ada.
  final int? badgeCount;

  /// Kalau true -> hanya dot kecil tanpa angka (abaikan badgeCount).
  final bool showBadgeDot;

  const NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badgeCount,
    this.showBadgeDot = false,
  });
}

/// NavigationBar versi “Cuan”
/// - Konsisten style antar page
/// - Support badge angka / dot
class CuanNavigationBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Opsi styling tambahan
  final NavigationDestinationLabelBehavior labelBehavior;
  final bool? indicator; // true = pakai indicator default; false = none
  final EdgeInsetsGeometry? padding;

  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final double? iconSize;

  /// Scale khusus untuk teks di nav bar (agar tidak terpengaruh setting OS yang besar)
  final double textScaleFactor;

  const CuanNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.labelBehavior = NavigationDestinationLabelBehavior.alwaysShow,
    this.indicator,
    this.padding,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.iconSize,
    this.textScaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final TextStyle defaultSelected = const TextStyle(
      fontSize: 10,
      height: 1.1,
      fontWeight: FontWeight.w700,
    );
    final TextStyle defaultUnselected = const TextStyle(
      fontSize: 10,
      height: 1.1,
      fontWeight: FontWeight.w500,
    );

    final navTheme = NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final base = states.contains(MaterialState.selected)
              ? (selectedLabelStyle ?? defaultSelected)
              : (unselectedLabelStyle ?? defaultUnselected);
          return base;
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(size: iconSize ?? 24);
        }),
        indicatorColor: (indicator ?? true)
            ? cs.secondary.withOpacity(.15)
            : Colors.transparent,
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        labelBehavior: labelBehavior,
        height: 72,
        destinations: items.map((it) {
          return NavigationDestination(
            icon: _IconWithBadge(
              icon: it.icon,
              badgeCount: it.badgeCount,
              dot: it.showBadgeDot,
              size: iconSize,
            ),
            selectedIcon: _IconWithBadge(
              icon: it.selectedIcon ?? it.icon,
              badgeCount: it.badgeCount,
              dot: it.showBadgeDot,
              selected: true,
              size: iconSize,
            ),
            label: it.label,
          );
        }).toList(),
      ),
    );

    // Clamp text scale khusus nav bar
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
      child: navTheme,
    );
  }
}

/// Icon + badge kecil (angka/dot)
class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final bool dot;
  final bool selected;
  final double? size;

  const _IconWithBadge({
    required this.icon,
    this.badgeCount,
    this.dot = false,
    this.selected = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: size), // ⬅️ hormati size dari atas
        if (dot || badgeCount != null)
          Positioned(
            right: -6,
            top: -4,
            child: badgeCount == null
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.error.withOpacity(.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
