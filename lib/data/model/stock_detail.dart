class StockDetail {
  final String ticker;
  final String companyName;
  final double? lastPrice;
  final double? prevClose;
  // NEW: OHLC dari GOAPI
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final String? logoUrl;
  StockDetail({
    required this.ticker,
    required this.companyName,
    this.lastPrice,
    this.prevClose,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.logoUrl,
  });

  factory StockDetail.fromJson(Map<String, dynamic> j) => StockDetail(
    ticker: j['ticker'] as String,
    companyName: j['company_name'] as String,
    lastPrice: (j['last_price'] as num?)?.toDouble(),
    prevClose: (j['prev_close'] as num?)?.toDouble(),
    openPrice: (j['open_price'] as num?)?.toDouble(),
    highPrice: (j['high_price'] as num?)?.toDouble(),
    lowPrice: (j['low_price'] as num?)?.toDouble(),
    logoUrl: j['logo_url'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'company_name': companyName,
    'last_price': lastPrice,
    'prev_close': prevClose,
    'open_price': openPrice,
    'high_price': highPrice,
    'low_price': lowPrice,
    'logo_url': logoUrl,
  };

  StockDetail copyWith({
    String? ticker,
    String? companyName,
    double? lastPrice,
    double? prevClose,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    String? logoUrl,
  }) {
    return StockDetail(
      ticker: ticker ?? this.ticker,
      companyName: companyName ?? this.companyName,
      lastPrice: lastPrice ?? this.lastPrice,
      prevClose: prevClose ?? this.prevClose,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
