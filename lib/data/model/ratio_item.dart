class RatioItem {
  final DateTime periodEnd;
  final double? per, pbvr, roe, der;
  RatioItem({required this.periodEnd, this.per, this.pbvr, this.roe, this.der});
  factory RatioItem.fromJson(Map<String, dynamic> j) => RatioItem(
    periodEnd: DateTime.parse(j['period_end'] as String),
    per: (j['per'] as num?)?.toDouble(),
    pbvr: (j['pbvr'] as num?)?.toDouble(),
    roe: (j['roe'] as num?)?.toDouble(),
    der: (j['der'] as num?)?.toDouble(),
  );
}
