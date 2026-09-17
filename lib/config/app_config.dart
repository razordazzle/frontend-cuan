import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  // static const baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://127.0.0.1:8000',
  // );
  static String get baseUrl {
    // Prioritaskan env (mis. --dart-define=API_BASE_URL=http://192.168.1.10:8000)
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return 'http://localhost:8000'; // web dev

    if (Platform.isAndroid) {
      // Untuk HP Fisik via kabel USB (wajib jalankan: adb reverse tcp:8000 tcp:8000)
      return 'http://127.0.0.1:8000';

      // Untuk Android Emulator (AVD):
      // return 'http://10.0.2.2:8000';
    }

    // iOS Simulator / desktop
    // return 'http://127.0.0.1:8000';
    // return 'http://www.cuandiara.com:8000';

    return 'https://www.cuandiara.com';
    // return 'http://104.248.155.164:8000';
  }

  static String get wsBaseUrl{
    return baseUrl.replaceFirst('https://','wss://').replaceFirst('http://','ws://');
  }
}