import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IHSG 2 desimal, saham bulat (header O/H/L/C chart extend)', () {
    expect(chartPricePrecisionFor('IHSG'), 2);
    expect(chartPricePrecisionFor('ihsg'), 2);
    expect(chartPricePrecisionFor(' IHSG '), 2);
    expect(chartPricePrecisionFor('BBCA'), 0);
    expect(chartPricePrecisionFor('GOTO'), 0);
    expect(chartPricePrecisionFor(''), 0);
  });

  test('pembulatan header sama dengan pembulatan label chart', () {
    expect(7234.5678.toStringAsFixed(chartPricePrecisionFor('IHSG')), '7234.57');
    expect(7234.5678.toStringAsFixed(chartPricePrecisionFor('BBCA')), '7235');
    expect(2940.0.toStringAsFixed(chartPricePrecisionFor('BBCA')), '2940');
  });
}
