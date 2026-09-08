// lib/data/model/search_models.dart
enum SearchKind { stock, journal, playlist }

SearchKind _kindFrom(String s) {
  switch (s) {
    case 'stock': return SearchKind.stock;
    case 'journal': return SearchKind.journal;
    case 'playlist': return SearchKind.playlist;
    default: return SearchKind.stock;
  }
}

class SearchResultItem {
  final SearchKind type;
  final String title;   // judul/namanya (opsional dari server tapi kita isi)
  final String? ticker; // untuk type=stock
  final String? id;     // untuk type=journal|playlist

  SearchResultItem({
    required this.type,
    required this.title,
    this.ticker,
    this.id,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    final t = _kindFrom(json['type'] as String);
    return SearchResultItem(
      type: t,
      title: (json['title'] as String?) ?? (json['ticker'] as String?) ?? '',
      ticker: json['ticker'] as String?,
      id: json['id'] as String?,
    );
  }
}

class SearchResponse {
  final List<SearchResultItem> results;
  SearchResponse({required this.results});
  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final arr = (json['results'] as List? ?? [])
        .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return SearchResponse(results: arr);
  }
}
