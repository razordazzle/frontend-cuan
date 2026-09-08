class TermsClause {
  final String title;
  final String body;
  const TermsClause({required this.title, required this.body});

  factory TermsClause.fromJson(Map<String, dynamic> j) =>
      TermsClause(title: j['title'] as String, body: j['body'] as String);
}