import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/rules/expense_rules.dart';

void main() {
  test('amount calculations follow precedence and reject invalid money', () {
    for (final entry in {
      '340/5': 68,
      '120+250': 370,
      '100-20*3': 40,
      '12×5÷3': 20,
      ' 0.5 * 100 ': 50,
      '100/5/2': 10,
      '100-20+5': 85,
    }.entries) {
      expect(moneyValue(entry.key), entry.value);
      expect(positiveMoney(entry.key), isNull);
    }
    for (final invalid in [
      '',
      '1/0',
      '5/2',
      '4-',
      '-5',
      '2++3',
      '1e3',
      '2abc',
      '0',
      '1-2',
      '999999999+1',
      '1..2'
    ]) {
      expect(moneyValue(invalid), isNull, reason: invalid);
      expect(positiveMoney(invalid), isNotNull);
    }
    expect(amountKey('340/5', '='), '68');
    expect(amountKey('12+', '⌫'), '12');
    expect(amountKey('1/0', '='), '1/0');
  });
}
