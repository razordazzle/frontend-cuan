class KeyStatsLatest {
  final double? per, pbv, roe, der, epsTtm;
  final double? sales,
      assets,
      liability,
      equity,
      operatingCashFlow,
      netCashFlow,
      capEx,
      opExp,
      operatingProfit,
      netProfit;
  final String? financialYearEnd;
  final double? issuedShares, dps, rps, bvps;
  final double? dividendYield, psr, pcfr;
  final double? dpr, gpm, opm, npm, ebitm, roa;
  final double? currentRatio, quickRatio, cashRatio;
  KeyStatsLatest({
    this.per,
    this.pbv,
    this.roe,
    this.der,
    this.epsTtm,
    this.sales,
    this.assets,
    this.liability,
    this.equity,
    this.operatingCashFlow,
    this.netCashFlow,
    this.capEx,
    this.opExp,
    this.operatingProfit,
    this.netProfit,
    this.financialYearEnd,
    this.issuedShares,
    this.dps,
    this.rps,
    this.bvps,
    this.dividendYield,
    this.psr,
    this.pcfr,
    this.dpr,
    this.gpm,
    this.opm,
    this.npm,
    this.ebitm,
    this.roa,
    this.currentRatio,
    this.quickRatio,
    this.cashRatio,
  });
  factory KeyStatsLatest.fromJson(Map<String, dynamic> j) => KeyStatsLatest(
    per: (j['per'] as num?)?.toDouble(),
    pbv: (j['pbvr'] as num?)?.toDouble(),
    roe: (j['roe'] as num?)?.toDouble(),
    der: (j['der'] as num?)?.toDouble(),
    epsTtm: (j['eps_ttm'] as num?)?.toDouble(),
    sales: (j['sales'] as num?)?.toDouble(),
    assets: (j['assets'] as num?)?.toDouble(),
    liability: (j['liability'] as num?)?.toDouble(),
    equity: (j['equity'] as num?)?.toDouble(),
    operatingCashFlow: (j['operating_cash_flow'] as num?)?.toDouble(),
    netCashFlow: (j['net_cash_flow'] as num?)?.toDouble(),
    capEx: (j['cap_ex'] as num?)?.toDouble(),
    opExp: (j['op_exp'] as num?)?.toDouble(),
    operatingProfit: (j['operating_profit'] as num?)?.toDouble(),
    netProfit: (j['net_profit'] as num?)?.toDouble(),
    financialYearEnd: j['financial_year_end'] as String?,
    issuedShares: (j['issued_shares'] as num?)?.toDouble(),
    dps: (j['dps'] as num?)?.toDouble(),
    rps: (j['rps'] as num?)?.toDouble(),
    bvps: (j['bvps'] as num?)?.toDouble(),

    dividendYield: (j['dividend_yield'] as num?)?.toDouble(),
    psr: (j['psr'] as num?)?.toDouble(),
    pcfr: (j['pcfr'] as num?)?.toDouble(),
    dpr: (j['dpr'] as num?)?.toDouble(),
    gpm: (j['gpm'] as num?)?.toDouble(),
    opm: (j['opm'] as num?)?.toDouble(),
    npm: (j['npm'] as num?)?.toDouble(),
    ebitm: (j['ebitm'] as num?)?.toDouble(),
    roa: (j['roa'] as num?)?.toDouble(),

    currentRatio: (j['current_ratio'] as num?)?.toDouble(),
    quickRatio: (j['quick_ratio'] as num?)?.toDouble(),
    cashRatio: (j['cash_ratio'] as num?)?.toDouble(),
  );
  // factory KeyStatsLatest.fromJson(Map<String, dynamic> json) {
  // return KeyStatsLatest(
  //   per: json['per']?.toDouble(),
  //   pbv: json['pbvr']?.toDouble() ?? json['pbv']?.toDouble(), // tangkap pbvr atau pbv
  //   roe: json['roe']?.toDouble(),
  //   der: json['der']?.toDouble(),
  //   epsTtm: json['eps_ttm']?.toDouble(),
  // );
  // }
}
