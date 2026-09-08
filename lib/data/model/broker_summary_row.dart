class BrokerSummaryRow {
  final DateTime? tradeDate;
  final String buyerCode;
  final String sellerCode;
  final num bVal;
  final num bLot;
  final num bAvg;
  final num sVal;
  final num sLot;
  final num sAvg;
  final int? bFreq;
  final int? sFreq;
  BrokerSummaryRow({
    this.tradeDate,
    required this.buyerCode,
    required this.sellerCode,
    required this.bVal,
    required this.bLot,
    required this.bAvg,
    required this.sVal,
    required this.sLot,
    required this.sAvg,
    this.bFreq,
    this.sFreq,
  });

  // helper biar aman kalau backend kadang kirim string / null
  static num _numOrZero(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory BrokerSummaryRow.fromJson(Map<String, dynamic> json) {
    // Tambahkan log ini di terminal Flutter buat nge-debug
    // print("DEBUG JSON BROKER: $json");

    DateTime? parsedDate;
    // Cek semua variasi nama field yang mungkin dikirim backend
    final dateVal = json['trade_date'] ?? json['tradeDate'] ?? '';
    if (dateVal.toString().isNotEmpty) {
      parsedDate = DateTime.tryParse(dateVal.toString());
    }

    return BrokerSummaryRow(
      tradeDate: parsedDate,
      buyerCode: (json['buyer_code'] ?? json['buyerCode'] ?? '').toString(),
      sellerCode: (json['seller_code'] ?? json['sellerCode'] ?? '').toString(),
      bVal: _numOrZero(json['b_val'] ?? json['bVal']),
      bLot: _numOrZero(json['b_lot'] ?? json['bLot']),
      bAvg: _numOrZero(json['b_avg'] ?? json['bAvg']),
      sVal: _numOrZero(json['s_val'] ?? json['sVal']),
      sLot: _numOrZero(json['s_lot'] ?? json['sLot']),
      sAvg: _numOrZero(json['s_avg'] ?? json['sAvg']),
      bFreq: _intOrNull(json['b_freq'] ?? json['bFreq']),
      sFreq: _intOrNull(json['s_freq'] ?? json['sFreq']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'trade_date': tradeDate,
      'buyer_code': buyerCode,
      'seller_code': sellerCode,
      'b_val': bVal,
      'b_lot': bLot,
      'b_avg': bAvg,
      's_val': sVal,
      's_lot': sLot,
      's_avg': sAvg,
      'b_freq': bFreq,
      's_freq': sFreq,
    };
  }
}
