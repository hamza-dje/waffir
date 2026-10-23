import 'package:wafir/data/serialization/budget_codec.dart';
import 'dart:convert';
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
  test(
      'migration preserves old money and expenses without preset products or reserves',
      () {
    final migrated = BudgetCodec.decode(jsonEncode({
      'budget': 3000,
      'fixedCosts': 500,
      'saved': 200,
      'days': 30,
      'start': start.toIso8601String(),
      'expenses': [Expense('Coffee', 50, start).toJson()],
      'pastExpenses': [Expense('Bus', 30, DateTime(2026, 9, 1)).toJson()]
    }));
    expect(migrated.active!.funds, 3000);
    expect(migrated.active!.balance, 2950);
    expect(migrated.active!.days, 30);
    expect(migrated.products, isEmpty);
    expect(migrated.budgets.first.legacy, isTrue);
    final restored = BudgetCodec.decode(migrated.encode());
    expect(restored.active!.expenses.single.label, 'Coffee');
    expect(restored.budgets.first.expenses.single.amount, 30);
  });
  test(
      'corrections validate date bounds and never change an existing carry-over',
      () {
    final closed = budget(expenses: [Expense('Food', 150, start)])
        .copyWith(closedAt: start);
    final next = BudgetRecord(
        id: 'next',
        funds: closed.balance,
        start: start,
        end: DateTime(2026, 10, 30),
        carriedFrom: closed.id,
        carriedAmount: closed.balance);
    final data = BudgetData(
        budgets: [closed, next],
        products: [const UsualProduct('Coffee', 50, 'coffee')]);
    final corrected =
        data.replace(closed.copyWith(expenses: [Expense('Food', 50, start)]));
    expect(corrected.active!.funds, 2850);
    expect(corrected.active!.carriedAmount, 2850);
    expect(corrected.budgets.first.balance, 2950);
    expect(closed.copyWith(start: DateTime(2026, 10, 2)).validate(), isNotNull);
    expect(BudgetCodec.decode(corrected.encode()).active!.carriedFrom, 'test');
  });
}
