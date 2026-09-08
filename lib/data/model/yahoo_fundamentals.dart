class YahooFundamentals {
  final String symbol;
  final String? mostRecentQuarter;

  final Map<String, dynamic> eps; // trailingEps, forwardEps
  final Map<String, dynamic>
  dividend; // dividendRate, dividendYield, payoutRatio, history
  final Map<String, dynamic>
  fundamental; // marketCap, sharesOutstanding, sector, dll
  final Map<String, dynamic>
  earnings; // revenue/netIncome ringkas kuartal terbaru
  final Map<String, dynamic> valuation; // PE, PB, EV/EBITDA, dll
  final Map<String, dynamic> profitability; // margins, ROE/ROA
  final Map<String, dynamic> liquidity;

  YahooFundamentals({
    required this.symbol,
    this.mostRecentQuarter,
    required this.eps,
    required this.dividend,
    required this.fundamental,
    required this.earnings,
    required this.valuation,
    required this.profitability,
    required this.liquidity,
  }); // currentRatio, quickRatio
  factory YahooFundamentals.fromJson(Map<String, dynamic> j) {
    // Map<String, dynamic> m(String k) =>
    //     (j[k] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    Map<String, dynamic> m(String k) {
      final v = j[k];
      if (v is Map) return v.cast<String, dynamic>();
      return <String, dynamic>{};
    }

    return YahooFundamentals(
      symbol: (j['symbol'] ?? '').toString(),
      mostRecentQuarter: j['mostRecentQuarter']?.toString(),
      eps: m('eps'),
      dividend: m('dividend'),
      fundamental: m('fundamental'),
      earnings: m('earnings'),
      valuation: m('valuation'),
      profitability: m('profitability'),
      liquidity: m('liquidity'),
    );
  }
}
