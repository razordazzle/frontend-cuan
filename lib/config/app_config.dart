import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  // static const baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://127.0.0.1:8000',
  // );
  static String get baseUrl {
    // Memaksa aplikasi selalu menembak ke backend lokal untuk presentasi PoC (mendukung Chrome & HP fisik via adb reverse)
    return 'http://127.0.0.1:8000';
  }

  static String get wsBaseUrl {
    return 'ws://127.0.0.1:8000';
  }
}
