class StockDetailResponse {
  final String ticker;
  final String companyName;
  final double? lastPrice;
  final double? prevClose;
  StockDetailResponse({
    required this.ticker,
    required this.companyName,
    this.lastPrice,
    this.prevClose,
  });

  factory StockDetailResponse.fromJson(Map<String, dynamic> j) =>
      StockDetailResponse(
        ticker: j['ticker'] as String,
        companyName: j['company_name'] as String,
        lastPrice: (j['last_price'] as num?)?.toDouble(),
        prevClose: (j['prev_close'] as num?)?.toDouble(),
      );
}
