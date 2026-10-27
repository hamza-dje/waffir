import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/domain/models/loan.dart';

void main() {
  test('four spending figures share the original budget and expense basis', () {
    // Synthetic records that reproduce the screenshot, not the user's saved data.
    final budget = BudgetRecord(
        id: 'b',
        funds: 10000,
        start: DateTime(2026, 10, 15),
        end: DateTime(2026, 11, 13),
        expenses: [Expense('Purchases', 2675, DateTime(2026, 10, 23))]);
    final loans = [
      for (final day in [24, 25])
        Loan(
            id: 'loan-$day',
            person: 'Example',
            amount: 1000,
            lent: true,
            date: DateTime(2026, 10, 20),
            due: DateTime(2026, 10, day),
            budgetId: 'b'),
    ];
    final figures = BudgetFigures(budget, DateTime(2026, 10, 24), loans: loans);
    expect(figures.remainingDays, 21);
    expect(figures.cash, 5325);
    expect(figures.transfers.expected, 2000);
    expect(figures.savings, closeTo(325, 1e-9));
    expect(figures.leftToday, closeTo(348.8095238095, 1e-8));
    expect(figures.upcoming, closeTo(366.25, 1e-9));
    expect(figures.tomorrowLimit, closeTo(991.6666666667, 1e-8));
  });

  test('loan cash and spending plan remain separate across the due date', () {
    final date = DateTime(2026, 10, 24);
    final budget = BudgetRecord(
        id: 'b', funds: 3000, start: date, end: DateTime(2026, 11, 22));
    final loan = Loan(
        id: 'l',
        person: 'Example',
        amount: 500,
        lent: true,
        date: date,
        due: date,
        budgetId: 'b');
    final figures = BudgetFigures(budget, date, loans: [loan]);
    expect(figures.todayLimit, 100);
    expect(figures.cash, 2500);
    expect(figures.upcoming, closeTo(3000 / 29, 1e-9));
    expect(figures.tomorrowLimit, 200);
    final nextDay =
        BudgetFigures(budget, DateTime(2026, 10, 25), loans: [loan]);
    expect(nextDay.todayLimit, closeTo(2500 / 29, 1e-9));
    expect(nextDay.savings, 100);
    expect(nextDay.tomorrowLimit, 300);
  });

  test(
      'spending changes both future estimates once, without counting loans as spending',
      () {
    final date = DateTime(2026, 10, 24);
    final budget = BudgetRecord(
        id: 'b',
        funds: 3000,
        start: date,
        end: DateTime(2026, 11, 22),
        expenses: [Expense('Food', 50, date)]);
    final baseline = BudgetFigures(budget, date);
    for (final lent in [true, false]) {
      for (final due in [null, date, DateTime(2026, 11, 30)]) {
        final loan = Loan(
            id: 'l',
            person: 'Example',
            amount: 500,
            lent: lent,
            date: date,
            due: due,
            budgetId: 'b',
            payments: [
              LoanPayment(id: 'p', amount: 100, date: date, budgetId: 'b')
            ]);
        final figures = BudgetFigures(budget, date, loans: [loan]);
        expect(figures.spentToday, baseline.spentToday);
        expect(figures.savings, baseline.savings);
        expect(figures.upcoming, baseline.upcoming);
        expect(figures.tomorrowLimit, baseline.tomorrowLimit);
        expect(figures.cash, lent ? 2550 : 3350);
      }
    }
    expect(baseline.tomorrowLimit, 150);
    expect(baseline.upcoming, closeTo(2950 / 29, 1e-9));
    // Spending the maximum tomorrow leaves the original average for every later day.
    expect(budget.balance - baseline.tomorrowLimit!,
        closeTo(baseline.original * (baseline.remainingDays - 2), 1e-9));
  });
}
