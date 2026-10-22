import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/budget_data.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  BudgetRecord budget({List<Expense> expenses = const [], int days = 30}) => BudgetRecord(
    id: 'test', funds: 3000, start: start, end: DateTime(2026,10,days), expenses: expenses);
  test('past, today, and upcoming days use separate balances', () {
    final first = BudgetFigures(budget(expenses: [Expense('Coffee',50,start)]), start);
    expect(first.original,100); expect(first.todayLimit,100); expect(first.leftToday,50);
    expect(first.upcoming,closeTo(2950/29,1e-9)); expect(first.savings,0);
    final second = BudgetFigures(budget(expenses: [Expense('Coffee',50,start),
      Expense('Food',100,DateTime(2026,10,2))]), DateTime(2026,10,2));
    expect(second.todayLimit,closeTo(2950/29,1e-9));
    expect(second.leftToday,closeTo(2950/29-100,1e-9));
    expect(second.upcoming,closeTo(2850/28,1e-9)); expect(second.savings,50);
    final over = BudgetFigures(budget(expenses: [Expense('Food',200,start)]),start);
    expect(over.leftToday,-100); expect(over.upcoming,closeTo(2800/29,1e-9));
    expect(BudgetFigures(over.budget,DateTime(2026,10,2)).savings,-100);
  });
  test('calendar edges have no division by zero or invented future allowance', () {
    final one = BudgetFigures(budget(days:1),start);
    expect(one.todayLimit,3000); expect(one.upcoming,isNull);
    final expired = BudgetFigures(budget(),DateTime(2026,10,31));
    expect(expired.remainingDays,0); expect(expired.leftToday,isNull); expect(expired.upcoming,isNull);
    expect(BudgetFigures(budget(),DateTime(2026,9,30)).todayLimit,isNull);
    expect(daysBetween(DateTime(2026,12,31),DateTime(2027,1,1)),1);
  });
  test('migration preserves old money and expenses without preset products or reserves', () {
    final migrated = BudgetData.decode(jsonEncode({'budget':3000,'fixedCosts':500,'saved':200,
      'days':30,'start':start.toIso8601String(),
      'expenses':[Expense('Coffee',50,start).toJson()],
      'pastExpenses':[Expense('Bus',30,DateTime(2026,9,1)).toJson()]}));
    expect(migrated.active!.funds,3000); expect(migrated.active!.balance,2950);
    expect(migrated.active!.days,30); expect(migrated.products,isEmpty);
    expect(migrated.budgets.first.legacy,isTrue);
    final restored = BudgetData.decode(migrated.encode());
    expect(restored.active!.expenses.single.label,'Coffee');
    expect(restored.budgets.first.expenses.single.amount,30);
  });
  test('corrections validate date bounds and never change an existing carry-over', () {
    final closed = budget(expenses:[Expense('Food',150,start)]).copyWith(closedAt:start);
    final next = BudgetRecord(id:'next',funds:closed.balance,start:start,end:DateTime(2026,10,30),
      carriedFrom:closed.id,carriedAmount:closed.balance);
    final data = BudgetData(budgets:[closed,next],products:[const UsualProduct('Coffee',50,'coffee')]);
    final corrected = data.replace(closed.copyWith(expenses:[Expense('Food',50,start)]));
    expect(corrected.active!.funds,2850); expect(corrected.active!.carriedAmount,2850);
    expect(corrected.budgets.first.balance,2950);
    expect(closed.copyWith(start:DateTime(2026,10,2)).validate(),isNotNull);
    expect(BudgetData.decode(corrected.encode()).active!.carriedFrom,'test');
  });
}
