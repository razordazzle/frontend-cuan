import 'package:cuan_app/utils/phone_format.dart';
import 'package:flutter/material.dart';

typedef Validator = String? Function(String? value);

class Validators {
  static Validator required([String msg = 'Wajib diisi']) =>
      (v) => (v == null || v.trim().isEmpty) ? msg : null;

  static Validator email([String msg = 'Email tidak valid']) => (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return msg;
        final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        return re.hasMatch(s) ? null : msg;
      };

  static Validator minLength(int n, [String? label]) => (v) {
        final s = (v ?? '').trim();
        return s.length >= n ? null : '${label ?? "Field"} minimal $n karakter';
      };

  static Validator match(TextEditingController other,
          [String msg = 'Tidak sama']) =>
      (v) => (v ?? '') == other.text ? null : msg;

  /// No. HP Indonesia. Boleh diketik 08xx / 8xx / 628xx / +628xx (spasi & strip diabaikan).
  /// Dicek setelah dinormalisasi ke E.164: harus +62 8 diikuti 8-11 digit (total 9-12 digit
  /// setelah +62). Dulu "08…" malah ditolak, dan nomor seperti 1812… bisa lolos di Edit Profil.
  static Validator phoneID([String msg = 'Nomor HP tidak valid']) => (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return msg;
        return isValidPhoneID(s) ? null : msg;
      };

  static bool isValidPhoneID(String raw) =>
      RegExp(r'^\+628\d{7,11}$').hasMatch(toE164ID(raw));
}
