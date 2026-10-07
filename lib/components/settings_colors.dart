import 'package:flutter/material.dart';

/// Palet warna modal settings indikator & color picker-nya, mengikuti tema dark/light.
/// Selaras dengan sheet drawing & timeframe (#121212 / putih).
@immutable
class SettingsColors {
  final Color sheetBg;
  final Color cardBg;
  final Color cardBorder;
  final Color closeButtonBg;
  final Color handle;
  final Color subtitle;
  final Color label;
  final Color disabledLabel;
  final Color disabledText;

  /// Ikon sekunder (panah dropdown, tombol +).
  final Color icon;

  /// Teks/ikon utama; juga latar elemen terpilih (tab aktif, checkbox, item dropdown, tombol Ok).
  final Color foreground;

  /// Teks/ikon di atas [foreground] (warna dibalik).
  final Color onForeground;

  /// Latar & border kontrol kecil (tombol swatch, segmented control di color picker).
  final Color controlBg;
  final Color controlBorder;

  /// Garis tepi tipis (tombol +, kotak persen opacity).
  final Color outline;
  final Color popoverBg;
  final Color popoverShadow;

  /// Dua warna pola kotak-kotak di belakang warna transparan.
  final Color checkerDark;
  final Color checkerLight;

  const SettingsColors._({
    required this.sheetBg,
    required this.cardBg,
    required this.cardBorder,
    required this.closeButtonBg,
    required this.handle,
    required this.subtitle,
    required this.label,
    required this.disabledLabel,
    required this.disabledText,
    required this.icon,
    required this.foreground,
    required this.onForeground,
    required this.controlBg,
    required this.controlBorder,
    required this.outline,
    required this.popoverBg,
    required this.popoverShadow,
    required this.checkerDark,
    required this.checkerLight,
  });

  static const SettingsColors dark = SettingsColors._(
    sheetBg: Color(0xFF121212),
    cardBg: Color(0xFF1E1E1E),
    cardBorder: Color(0xFF2C2C2E),
    closeButtonBg: Color(0xFF242426),
    handle: Color(0xFF3E3E42),
    subtitle: Color(0xFF8E8E93),
    label: Color(0xFFD1D4DC),
    disabledLabel: Color(0xFF787B86),
    disabledText: Color(0xFF50535E),
    icon: Color(0xFF868993),
    foreground: Colors.white,
    onForeground: Colors.black,
    controlBg: Color(0xFF2A2A2A),
    controlBorder: Color(0xFF3A3A3C),
    outline: Color(0xFF434651),
    popoverBg: Color(0xFF1E1E1E),
    popoverShadow: Color(0xBF000000),
    checkerDark: Color(0xFF1E222D),
    checkerLight: Color(0xFF2A2E39),
  );

  static const SettingsColors light = SettingsColors._(
    sheetBg: Colors.white,
    cardBg: Color(0xFFF0F3FA),
    cardBorder: Color(0xFFE0E3EB),
    closeButtonBg: Color(0xFFF0F3FA),
    handle: Color(0xFFD1D4DC),
    subtitle: Color(0xFF9598A1),
    label: Color(0xFF434651),
    disabledLabel: Color(0xFFB2B5BE),
    disabledText: Color(0xFFB2B5BE),
    icon: Color(0xFF787B86),
    foreground: Color(0xFF131722),
    onForeground: Colors.white,
    controlBg: Color(0xFFF0F3FA),
    controlBorder: Color(0xFFD1D4DC),
    outline: Color(0xFFB2B5BE),
    popoverBg: Colors.white,
    popoverShadow: Color(0x33000000),
    checkerDark: Color(0xFFE0E3EB),
    checkerLight: Colors.white,
  );

  static SettingsColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
