import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

/// Set favorit (urut sesuai waktu ditambahkan) yang tersimpan di device lewat SharedPreferences.
///
/// Mulai dari [defaults], lalu diganti data tersimpan begitu selesai dimuat, kecuali user
/// sudah mengubah favorit lebih dulu (perubahan user tidak boleh tertimpa data lama).
class PersistedFavorites<T extends Object> {
  final String _storageKey;
  final String Function(T item) _encode;
  final T? Function(String value) _decode;
  final LinkedHashSet<T> _items;
  bool _hasLocalChanges = false;

  PersistedFavorites({
    required String storageKey,
    required Iterable<T> defaults,
    required String Function(T item) encode,
    required T? Function(String value) decode,
  }) : _storageKey = storageKey,
       _encode = encode,
       _decode = decode,
       _items = LinkedHashSet<T>.of(defaults);

  Set<T> get items => UnmodifiableSetView<T>(_items);

  bool contains(T item) => _items.contains(item);

  /// Muat dari device. Return true kalau isi favorit berubah (untuk memicu rebuild).
  Future<bool> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList(_storageKey);
    if (saved == null || _hasLocalChanges) return false;
    // Nilai yang tidak dikenal lagi (mis. tool yang sudah dihapus) dibuang.
    _items
      ..clear()
      ..addAll(saved.map(_decode).whereType<T>());
    return true;
  }

  void toggle(T item) {
    if (!_items.remove(item)) _items.add(item);
    _hasLocalChanges = true;
    final List<String> snapshot = _items.map(_encode).toList();
    SharedPreferences.getInstance().then(
      (SharedPreferences prefs) => prefs.setStringList(_storageKey, snapshot),
    );
  }
}
