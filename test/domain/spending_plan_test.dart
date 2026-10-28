import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/domain/models/spending_plan.dart';
import 'package:wafir/data/serialization/budget_codec.dart';
import 'package:wafir/presentation/controllers/budget_book.dart';
import '../presentation/budget_book_test.dart' show MemoryBudgetStorage;

void main() {
  final now = DateTime(2026, 10, 28, 12);
  final today = dayOnly(now);
  BudgetRecord budget() => BudgetRecord(
      id: 'b', funds: 3000, start: today, end: DateTime(2026, 11, 26));
  SpendingPlan plan({int amount = 300, List<PlanDay>? days}) => SpendingPlan(
      id: 'p',
      budgetId: 'b',
      label: 'Books',
      days: days ?? [PlanDay(id: 'd', date: today, amount: amount)]);
  Future<BudgetBook> open(MemoryBudgetStorage storage) async {
    final b = BudgetBook(storage, now: () => now);
    expect(await b.load(), isTrue);
    addTearDown(b.dispose);
    return b;
  }

  test('whole dinars split across distinct sorted dates without losing money',
      () {
    final days = SpendingPlan.split(
        [DateTime(2026, 10, 30), today, DateTime(2026, 10, 29)],
        100,
        false,
        's');
    expect(days.map((d) => d.amount), [34, 33, 33]);
    expect(days.first.date, today);
    expect(
        SpendingPlan.split(days.map((d) => d.date).toList(), 100, true, 's')
            .fold<int>(0, (s, d) => s + d.amount),
        300);
    expect(
        plan(
                days: SpendingPlan.split(
                    days.map((d) => d.date).toList(), 2, false, 's'))
            .validate(budget()),
        isNotNull);
  });
  test(
      'reservation, actual spending and correction count money once and survive restart',
      () async {
    final store = MemoryBudgetStorage(BudgetData(budgets: [budget()]).encode());
    final book = await open(store);
    expect(await book.savePlan(plan()), isTrue);
    expect(book.figures(book.data.active!).todayLimit, 90);
    expect(book.figures(book.data.active!).cash, 3000);
    expect(await book.recordPlanDay('p', 'd', Expense('Books', 300, today)),
        isTrue);
    expect(book.figures(book.data.active!).leftToday, 90);
    expect(book.figures(book.data.active!).spentToday, 300);
    expect(book.figures(book.data.active!).plannedReserved, 0);
    expect(await book.recordPlanDay('p', 'd', Expense('Books', 300, today)),
        isFalse);
    expect(await book.correctExpense('b', 0, Expense('Books', 240, today)),
        isTrue);
    expect(book.figures(book.data.active!).leftToday, 92);
    final restarted = await open(store);
    expect(restarted.data.plans.single.days.single.expenseId,
        restarted.data.active!.expenses.single.id);
    expect(await restarted.correctExpense('b', 0, null), isTrue);
    expect(restarted.data.plans.single.reserved, 300);
    expect(restarted.figures(restarted.data.active!).leftToday, 90);
    expect(
        await restarted.setProducts([const UsualProduct('Tea', 20)]), isTrue);
    expect(restarted.data.plans.length, 1);
    expect(await restarted.deletePlan('p'), isTrue);
    expect(restarted.figures(restarted.data.active!).leftToday, 100);
  });
  test(
      'missed dates stay reserved, failures keep data, and stopping keeps review history',
      () async {
    final b = budget().copyWith(start: DateTime(2026, 10, 27));
    final p = plan(days: [
      PlanDay(id: 'missed', date: DateTime(2026, 10, 27), amount: 300)
    ]);
    final store =
        MemoryBudgetStorage(BudgetData(budgets: [b], plans: [p]).encode());
    final book = await open(store);
    expect(p.needsReview(now, b), isTrue);
    expect(book.figures(b).plannedReserved, 300);
    store.accept = false;
    expect(await book.cancelPlanDay('p', 'missed'), isFalse);
    expect(book.data.plans.single.reserved, 300);
    store.accept = true;
    expect(await book.stopBudget('b'), isTrue);
    expect(book.data.plans.single.reserved, 300);
    expect(
        await book.recordPlanDay('p', 'missed', Expense('Books', 300, today)),
        isFalse);
    expect(await book.cancelPlanDay('p', 'missed'), isTrue);
    expect(book.data.plans.single.complete, isTrue);
  });
  test(
      'future recording and date exclusions are blocked, deleting a plan keeps expenses',
      () async {
    final future = DateTime(2026, 10, 29);
    final store = MemoryBudgetStorage(BudgetData(budgets: [budget()]).encode());
    final book = await open(store);
    expect(
        await book.savePlan(
            plan(days: [PlanDay(id: 'f', date: future, amount: 200)])),
        isTrue);
    expect(await book.recordPlanDay('p', 'f', Expense('Books', 200, today)),
        isFalse);
    expect(await book.correctBudget(budget().copyWith(end: today)), isFalse);
    expect(await book.deletePlan('p'), isTrue);
    expect(await book.savePlan(plan()), isTrue);
    expect(await book.recordPlanDay('p', 'd', Expense('Books', 300, today)),
        isTrue);
    final limit = book.figures(book.data.active!).leftToday;
    expect(await book.deletePlan('p'), isTrue);
    expect(book.data.active!.expenses.single.amount, 300);
    expect(book.figures(book.data.active!).leftToday, limit);
    expect(BudgetCodec.decode(store.value!).plans, isEmpty);
  });

  test('moving unfinished days preserves completed days in the saved budget',
      () async {
    final store = MemoryBudgetStorage(BudgetData(budgets: [budget()]).encode());
    final book = await open(store);
    expect(
        await book.savePlan(plan(days: [
          PlanDay(id: 'd', date: today, amount: 300),
          PlanDay(id: 'later', date: DateTime(2026, 10, 29), amount: 200),
        ])),
        isTrue);
    expect(await book.recordPlanDay('p', 'd', Expense('Books', 300, today)),
        isTrue);
    expect(await book.stopBudget('b'), isTrue);
    expect(await book.startBudget(2700, today, DateTime(2026, 11, 26), []),
        isTrue);
    final active = book.data.active!;
    expect(book.figures(active).plannedReserved, 0);
    expect(
        await book.savePlan(SpendingPlan(
            id: 'p',
            budgetId: active.id,
            label: 'Books',
            days: [
              PlanDay(id: 'later', date: DateTime(2026, 10, 29), amount: 200)
            ])),
        isTrue);
    expect(book.data.plans.length, 2);
    expect(book.data.plans.first.complete, isTrue);
    expect(book.data.plans.first.budgetId, 'b');
    expect(book.figures(active).plannedReserved, 200);
    final restarted = await open(store);
    expect(restarted.data.plans.length, 2);
    expect(restarted.data.budgets.first.expenses.single.amount, 300);
  });

  test(
      'old storage migrates without invented plans and shortfalls can be reviewed',
      () async {
    final raw = BudgetData(budgets: [budget()])
        .encode()
        .replaceFirst('"version":4', '"version":3');
    final store = MemoryBudgetStorage(raw);
    final book = await open(store);
    expect(book.data.plans, isEmpty);
    expect(await book.savePlan(plan(amount: 3500)), isTrue);
    expect(book.figures(book.data.active!).todayLimit, lessThan(0));
    expect(book.figures(book.data.active!).original, 100);
    expect(book.figures(book.data.active!).cash, 3000);
    expect(await book.cancelPlanDay('p', 'd'), isTrue);
    expect(book.figures(book.data.active!).leftToday, 100);
  });
}
