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

  /// Contoh sederhana untuk no. HP (bisa kamu perketat sesuai kebutuhan)
  static Validator phoneID([String msg = 'Nomor HP tidak valid']) => (v) {
        final s = (v ?? '').replaceAll(RegExp(r'\s+'), '');
        final re = RegExp(r'^(?:\+628|8)\d{7,12}$'); // +628… atau 08…
        return re.hasMatch(s) ? null : msg;
      };
}
