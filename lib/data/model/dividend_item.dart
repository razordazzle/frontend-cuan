class DividendItem {
  final int year;
  final double? dps, amountIdr;
  final String? cumDate, exDate, payDate;
  DividendItem({
    required this.year, this.dps, this.amountIdr, this.cumDate, this.exDate, this.payDate,
  });

  factory DividendItem.fromJson(Map<String, dynamic> j) => DividendItem(
    year: j['year'] as int,
    dps: (j['dps'] as num?)?.toDouble(),
    amountIdr: (j['amount_idr'] as num?)?.toDouble(),
    cumDate: j['cum_date'] as String?, exDate: j['ex_date'] as String?, payDate: j['pay_date'] as String?,
  );
}
