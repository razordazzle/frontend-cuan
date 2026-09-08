// lib/styles/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ColorScheme untuk Light
  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: Colors.red.shade700,
    onError: AppColors.white,
    background: Colors.white,
    onBackground: AppColors.font2,
    surface: Colors.white,
    onSurface: AppColors.font2,
  );

  // ColorScheme untuk Dark
  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brand,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: Colors.red.shade300,
    onError: AppColors.black,
    background: AppColors.background,
    onBackground: AppColors.font1,
    surface: AppColors.secondary, // panel/card
    onSurface: AppColors.font1,
  );
  static ThemeData get light => _base(light: true).copyWith(
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: _lightScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightScheme.background,
      foregroundColor: _lightScheme.onBackground,
      elevation: 0,
      centerTitle: true,
    ),
    // Tambahan:
    iconTheme: IconThemeData(color: _lightScheme.onBackground),
    listTileTheme: ListTileThemeData(
      iconColor: _lightScheme.onSurface,
      textColor: _lightScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: _lightScheme.outline.withOpacity(0.3),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _lightScheme.inverseSurface,
      contentTextStyle: TextStyle(color: _lightScheme.onInverseSurface),
      actionTextColor: _lightScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lightScheme.surface,
      surfaceTintColor: _lightScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightScheme.primary,
      foregroundColor: _lightScheme.onPrimary,
      elevation: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _lightScheme.surface,
      indicatorColor: _lightScheme.primary.withOpacity(0.15),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: _lightScheme.onSurface),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: _lightScheme.onSurface),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightScheme.surface,
      selectedItemColor: _lightScheme.primary,
      unselectedItemColor: _lightScheme.onSurface.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStatePropertyAll(_lightScheme.primary),
      checkColor: WidgetStatePropertyAll(_lightScheme.onPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? _lightScheme.primary.withOpacity(0.5)
            : _lightScheme.outline.withOpacity(0.3),
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? _lightScheme.primary
            : _lightScheme.surface,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStatePropertyAll(_lightScheme.primary),
    ),

    inputDecorationTheme: _inputDecoration(_lightScheme),
    elevatedButtonTheme: _elevatedButton(_lightScheme),
    textButtonTheme: _textButton(_lightScheme),
    outlinedButtonTheme: _outlinedButton(_lightScheme),
    cardTheme: CardThemeData(
      color: _lightScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData get dark => _base(light: false).copyWith(
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: _darkScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkScheme.background,
      foregroundColor: _darkScheme.onBackground,
      elevation: 0,
      centerTitle: true,
    ),
    iconTheme: IconThemeData(color: _darkScheme.onBackground),
    listTileTheme: ListTileThemeData(
      iconColor: _darkScheme.onSurface,
      textColor: _darkScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: _darkScheme.outline.withOpacity(0.3),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkScheme.inverseSurface,
      contentTextStyle: TextStyle(color: _darkScheme.onInverseSurface),
      actionTextColor: _darkScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkScheme.surface,
      surfaceTintColor: _darkScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkScheme.primary,
      foregroundColor: _darkScheme.onPrimary,
      elevation: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkScheme.surface,
      indicatorColor: _darkScheme.primary.withOpacity(0.25),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: _darkScheme.onSurface),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: _darkScheme.onSurface),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkScheme.surface,
      selectedItemColor: _darkScheme.primary,
      unselectedItemColor: _darkScheme.onSurface.withOpacity(0.7),
      type: BottomNavigationBarType.fixed,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStatePropertyAll(_darkScheme.primary),
      checkColor: WidgetStatePropertyAll(_darkScheme.onPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? _darkScheme.primary.withOpacity(0.5)
            : _darkScheme.outline.withOpacity(0.3),
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? _darkScheme.primary
            : _darkScheme.surface,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStatePropertyAll(_darkScheme.primary),
    ),

    inputDecorationTheme: _inputDecoration(_darkScheme),
    elevatedButtonTheme: _elevatedButton(_darkScheme),
    textButtonTheme: _textButton(_darkScheme),
    outlinedButtonTheme: _outlinedButton(_darkScheme),
    cardTheme: CardThemeData(
      color: _darkScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Base config yang sama untuk light/dark
  static ThemeData _base({required bool light}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: light ? Brightness.light : Brightness.dark,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        headlineMedium: TextStyle(fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontWeight: FontWeight.w600), // button
      ),
    );
    return base;
  }

  // === Helpers ===
  static InputDecorationTheme _inputDecoration(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldColor,
      hintStyle: const TextStyle(color: AppColors.hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButton(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextButtonThemeData _textButton(ColorScheme scheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButton(ColorScheme scheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'app_colors.dart';

// class AppTheme {
//   // Light Theme
//   static final ThemeData lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primaryColor: AppColors.primary,
//     scaffoldBackgroundColor: Colors.white,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.white,
//       foregroundColor: AppColors.black, // text/icon color
//       elevation: 0,
//     ),
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: AppColors.font2),
//       bodyMedium: TextStyle(color: AppColors.font2),
//       bodySmall: TextStyle(color: AppColors.disableFont),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: AppColors.fieldColor,
//       hintStyle: const TextStyle(color: AppColors.hintColor),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide.none,
//       ),
//     ),
//     buttonTheme: const ButtonThemeData(
//       buttonColor: AppColors.primary,
//       disabledColor: AppColors.disableButton,
//     ),
//   );

//   // Dark Theme
//   static final ThemeData darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primaryColor: AppColors.primary,
//     scaffoldBackgroundColor: AppColors.background,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.background,
//       foregroundColor: AppColors.font1,
//       elevation: 0,
//     ),
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: AppColors.font1),
//       bodyMedium: TextStyle(color: AppColors.font1),
//       bodySmall: TextStyle(color: AppColors.disableFont),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: AppColors.fieldColor,
//       hintStyle: const TextStyle(color: AppColors.hintColor),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.all(Radius.circular(8)),
//         borderSide: BorderSide.none,
//       ),
//     ),
//     buttonTheme: const ButtonThemeData(
//       buttonColor: AppColors.secondary,
//       disabledColor: AppColors.disableButton,
//     ),
//   );
// }
