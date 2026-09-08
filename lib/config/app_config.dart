import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  // static const baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://127.0.0.1:8000',
  // );
  static String get baseUrl {
    // Memaksa aplikasi selalu menembak ke backend lokal untuk presentasi PoC
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }
}
