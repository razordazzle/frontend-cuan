import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cuan_app/data/model/broker_summary_row.dart';

const _localColor = Color(0xFFFFC107);
const _foreignColor = Color(0xFFD32F2F);
const _bumnColor = Color(0xFF00BCD4);

class BrokerSummaryTable extends StatelessWidget {
  final List<BrokerSummaryRow> rows;
  final Map<String, String> brokerCategory;

  const BrokerSummaryTable({
    super.key,
    required this.rows,
    required this.brokerCategory,
  });

  String _fmtNum(num? v) {
    if (v == null) return '-';
    return NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: '',
    ).format(v);
  }

  Color _buyerColor(String code, ColorScheme cs) {
    final cat = brokerCategory[code.toUpperCase()];
    switch (cat) {
      case 'local':
        return _localColor;
      case 'foreign':
        return _foreignColor;
      case 'bumn':
        return _bumnColor;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    const wCode = 48.0;
    const wNum = 72.0;
    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    final headStyle = t.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final buyerNumStyle = t.bodyMedium?.copyWith(
      color: Colors.greenAccent,
      fontWeight: FontWeight.w700,
    );
    final sellerStyle = t.bodyMedium?.copyWith(
      color: Colors.redAccent,
      fontWeight: FontWeight.w700,
    );

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: wCode,
                        child: Text('Buyer', style: headStyle),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(child: Text('B.Val', style: headStyle)),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(child: Text('B.Lot', style: headStyle)),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(child: Text('B.Avg', style: headStyle)),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: wCode,
                        child: Center(child: Text('Seller', style: headStyle)),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('S.Val', style: headStyle),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outline.withOpacity(.12)),
                for (int i = 0; i < rows.length; i++) ...[
                  Container(
                    color: i.isEven
                        ? cs.surface
                        : cs.surfaceVariant.withOpacity(.06),
                    padding: pad,
                    child: Row(
                      children: [
                        SizedBox(
                          width: wCode,
                          child: Text(
                            rows[i].buyerCode,
                            style: t.bodyMedium?.copyWith(
                              color: _buyerColor(rows[i].buyerCode, cs),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              _fmtNum(rows[i].bVal),
                              style: buyerNumStyle,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              _fmtNum(rows[i].bLot),
                              style: buyerNumStyle,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              _fmtNum(rows[i].bAvg),
                              style: buyerNumStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: wCode,
                          child: Center(
                            child: Text(rows[i].sellerCode, style: sellerStyle),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _fmtNum(rows[i].sVal),
                              style: sellerStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != rows.length - 1)
                    Divider(height: 1, color: cs.outline.withOpacity(.06)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}