import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokens {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn; // seconds

  AuthTokens({required this.accessToken, this.refreshToken, this.expiresIn});

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
  };

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
    expiresIn: json['expiresIn'] as int?,
  );
}


abstract class IAuthStorage {
Future<void> save(AuthTokens tokens);
Future<AuthTokens?> read();
Future<void> clear();
}


class SecureAuthStorage implements IAuthStorage {
static const _key = 'auth_tokens';
final FlutterSecureStorage _secure = const FlutterSecureStorage();


@override
Future<void> save(AuthTokens tokens) async {
await _secure.write(key: _key, value: jsonEncode(tokens.toJson()));
}


@override
Future<AuthTokens?> read() async {
final raw = await _secure.read(key: _key);
if (raw == null) return null;
return AuthTokens.fromJson(jsonDecode(raw));
}


@override
Future<void> clear() async {
await _secure.delete(key: _key);
}
}


/// Fallback untuk Web/dev jika secure storage tidak tersedia
class PrefsAuthStorage implements IAuthStorage {
static const _key = 'auth_tokens';


@override
Future<void> save(AuthTokens tokens) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_key, jsonEncode(tokens.toJson()));
}


@override
Future<AuthTokens?> read() async {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_key);
if (raw == null) return null;
return AuthTokens.fromJson(jsonDecode(raw));
}


@override
Future<void> clear() async {
final prefs = await SharedPreferences.getInstance();
await prefs.remove(_key);
}
}


IAuthStorage buildAuthStorage() {
// Web gunakan SharedPreferences; mobile gunakan SecureStorage
if (kIsWeb) return PrefsAuthStorage();
return SecureAuthStorage();
}
