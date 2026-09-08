class MarketItem{
  final String ticker;
  final String companyName;
  final double? lastPrice;
  final double? changePoint;
  final double? changePct;
  final int? volume;
  final String? logoUrl;

  MarketItem({
    required this.ticker,
    required this.companyName,
    this.lastPrice,
    this.changePoint,
    this.changePct,
    this.volume,
    this.logoUrl,
  });

  factory MarketItem.fromJson(Map<String, dynamic> j) => MarketItem(
    ticker: j['ticker'] as String,
    companyName: j['company_name'] as String,
    lastPrice: (j['last_price'] as num?)?.toDouble(),
    changePoint: (j['change_point'] as num?)?.toDouble(),
    changePct: (j['change_pct'] as num?)?.toDouble(),
    volume: j['volume'] as int?,
    logoUrl: j['logo_url'] as String?,
  );
}