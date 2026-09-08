class FaqItem {
  final String? category;
  final String q;
  final String a;
  FaqItem({this.category, required this.q, required this.a});

  factory FaqItem.fromJson(Map<String, dynamic> j) => FaqItem(
    category: j['category'] as String?,
    q: j['q'] as String,
    a: j['a'] as String,
  );
}
