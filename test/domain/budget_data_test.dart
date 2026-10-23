import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  BudgetRecord budget({List<Expense> expenses = const [], int days = 30}) =>
      BudgetRecord(
          id: 'test',
          funds: 3000,
          start: start,
          end: DateTime(2026, 10, days),
          expenses: expenses);
  test('past, today, and upcoming days use separate balances', () {
    final first =
        BudgetFigures(budget(expenses: [Expense('Coffee', 50, start)]), start);
    expect(first.original, 100);
    expect(first.todayLimit, 100);
    expect(first.leftToday, 50);
    expect(first.upcoming, closeTo(2950 / 29, 1e-9));
    expect(first.savings, 0);
    expect(first.tomorrowLimit, 150);
    final second = BudgetFigures(
        budget(expenses: [
          Expense('Coffee', 50, start),
          Expense('Food', 100, DateTime(2026, 10, 2))
        ]),
        DateTime(2026, 10, 2));
    expect(second.todayLimit, closeTo(2950 / 29, 1e-9));
    expect(second.leftToday, closeTo(2950 / 29 - 100, 1e-9));
    expect(second.upcoming, closeTo(2850 / 28, 1e-9));
    expect(second.savings, 50);
    expect(second.tomorrowLimit, 150);
    final example = BudgetFigures(
        budget(expenses: [
          Expense('Coffee', 50, start),
          Expense('Coffee', 50, DateTime(2026, 10, 2))
        ]),
        DateTime(2026, 10, 2));
    expect(example.tomorrowLimit, 200);
    expect(example.budget.balance - example.tomorrowLimit!,
        example.original * (example.remainingDays - 2));
    final over =
        BudgetFigures(budget(expenses: [Expense('Food', 200, start)]), start);
    expect(over.leftToday, -100);
    expect(over.upcoming, closeTo(2800 / 29, 1e-9));
    expect(BudgetFigures(over.budget, DateTime(2026, 10, 2)).savings, -100);
  });
  test('calendar edges have no division by zero or invented future allowance',
      () {
    final one = BudgetFigures(budget(days: 1), start);
    expect(one.todayLimit, 3000);
    expect(one.upcoming, isNull);
    expect(one.tomorrowLimit, isNull);
    final nearEnd = BudgetRecord(
        id: 'two',
        funds: 200,
        start: start,
        end: DateTime(2026, 10, 2),
        expenses: [Expense('Food', 180, start)]);
    expect(BudgetFigures(nearEnd, start).tomorrowLimit, 20);
    final expired = BudgetFigures(budget(), DateTime(2026, 10, 31));
    expect(expired.remainingDays, 0);
    expect(expired.leftToday, isNull);
    expect(expired.upcoming, isNull);
    expect(BudgetFigures(budget(), DateTime(2026, 9, 30)).todayLimit, isNull);
    expect(daysBetween(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 1);
  });
}
