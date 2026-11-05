class StockListItem {
  final String ticker;
  final String companyName;
  final double? lastPrice;
  final double? prevClose;
  final double? changePoint;
  final double? changePct;
  final String? logoUrl;

  /// Net asing dalam Rupiah (+ beli bersih, - jual bersih). Hanya terisi di Top Net Foreign.
  final double? netForeignIdr;

  /// Net asing sebagai % dari nilai transaksi saham itu.
  final double? netForeignPct;

  StockListItem({
    required this.ticker,
    required this.companyName,
    this.lastPrice,
    this.prevClose,
    this.changePoint,
    this.changePct,
    this.logoUrl,
    this.netForeignIdr,
    this.netForeignPct,
  });

  factory StockListItem.fromJson(Map<String, dynamic> json) {
    return StockListItem(
      ticker: json['ticker'] as String,
      companyName: json['company_name'] as String,
      lastPrice: (json['last_price'] as num?)?.toDouble(),
      prevClose: (json['prev_close'] as num?)?.toDouble(),
      changePoint: (json['change_point'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      logoUrl: json['logo_url'] as String?,
      netForeignIdr: (json['net_foreign_idr'] as num?)?.toDouble(),
      netForeignPct: (json['net_foreign_pct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'company_name': companyName,
    'last_price': lastPrice,
    'prev_close': prevClose,
    'change_point': changePoint,
    'change_pct': changePct,
    'logo_url': logoUrl,
    'net_foreign_idr': netForeignIdr,
    'net_foreign_pct': netForeignPct,
  };

  // 👇 tambahin ini
  StockListItem copyWith({
    double? lastPrice,
    double? changePoint,
    double? prevClose,
    double? changePct,
    String? logoUrl,
  }) {
    return StockListItem(
      ticker: ticker,
      companyName: companyName,
      lastPrice: lastPrice ?? this.lastPrice,
      prevClose: prevClose ?? this.prevClose,
      changePoint: changePoint ?? this.changePoint,
      changePct: changePct ?? this.changePct,
      logoUrl: logoUrl ?? this.logoUrl,
      netForeignIdr: netForeignIdr,
      netForeignPct: netForeignPct,
    );
  }
}
