import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode;
  ThemeMode get mode => _mode;

  ThemeController(this._mode);

  static const _kKey = 'theme_mode';

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey) ?? 'system';
    return ThemeController(_decode(raw));
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, _encode(mode));
  }

  static String _encode(ThemeMode m) =>
      m == ThemeMode.light ? 'light' : m == ThemeMode.dark ? 'dark' : 'system';
  static ThemeMode _decode(String v) =>
      v == 'light' ? ThemeMode.light : v == 'dark' ? ThemeMode.dark : ThemeMode.system;
}
