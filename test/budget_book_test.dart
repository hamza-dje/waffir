import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/budget_book.dart';
import 'package:wafir/budget_data.dart';

class MemoryBudgetStorage implements BudgetStorage {
  MemoryBudgetStorage([this.value]);
  String? value;
  bool accept = true;
  bool throwWrite = false;
  Completer<bool>? pending;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<bool> write(String next) async {
    writes++;
    if (throwWrite) throw StateError('disk unavailable');
    final ok = pending == null ? accept : await pending!.future;
    if (ok) value = next;
    return ok;
  }
}

void main() {
  final now = DateTime(2026, 10, 23, 15);
  BudgetRecord record({List<Expense> expenses = const []}) => BudgetRecord(
      id: 'seed',
      funds: 3000,
      start: dayOnly(now),
      end: DateTime(2026, 11, 21),
      expenses: expenses);
  Future<BudgetBook> open(MemoryBudgetStorage storage) async {
    final book = BudgetBook(storage, now: () => now);
    expect(await book.load(), isTrue);
    addTearDown(book.dispose);
    return book;
  }

  test('a write failure does not publish state; a retry can succeed', () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    final original = storage.value;
    storage.accept = false;
    expect(await book.logExpense(Expense('Coffee', 50, now)), isFalse);
    expect(book.data.active!.spent, 0);
    expect(storage.value, original);
    expect(book.saving, isFalse);
    expect(book.error, contains('Could not save'));
    storage.accept = true;
    expect(await book.logExpense(Expense('Coffee', 50, now)), isTrue);
    expect(book.data.active!.spent, 50);
    expect(BudgetData.decode(storage.value!).active!.spent, 50);
    expect(book.error, isNull);
  });

  test('busy saves cannot overwrite pending state; publish follows durability',
      () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    storage.pending = Completer<bool>();
    final saving = book.logExpense(Expense('Coffee', 50, now));
    expect(book.saving, isTrue);
    expect(book.data.active!.spent, 0);
    expect(await book.logExpense(Expense('Bus', 30, now)), isFalse);
    expect(storage.writes, 1);
    storage.pending!.complete(true);
    expect(await saving, isTrue);
    expect(book.data.active!.expenses.single.label, 'Coffee');
  });

  test('storage exceptions keep data and release the busy state', () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    storage.throwWrite = true;
    expect(await book.stopBudget('seed'), isFalse);
    expect(book.data.active, isNotNull);
    expect(book.saving, isFalse);
  });

  test('stop, carry, correction and restart keep transfers fixed', () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    expect(await book.startBudget(100, now, now, []), isFalse);
    expect(await book.logExpense(Expense('Lunch', 150, now)), isTrue);
    expect(await book.stopBudget('seed'), isTrue);
    expect(await book.logExpense(Expense('Late', 1, now)), isFalse);
    expect(
        await book.startBudget(2850, dayOnly(now), DateTime(2026, 11, 21), [],
            carryFrom: 'seed'),
        isTrue);
    expect(await book.correctExpense('seed', 0, Expense('Lunch', 50, now)),
        isTrue);
    expect(book.data.budgets.first.balance, 2950);
    expect(book.data.active!.funds, 2850);
    expect(book.data.active!.carriedAmount, 2850);
    final restarted = await open(storage);
    expect(restarted.data.active!.carriedFrom, 'seed');
    expect(restarted.data.active!.carriedAmount, 2850);
  });

  test('all expense entry paths reject invalid money and time without writes',
      () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    for (final expense in [
      Expense('Zero', 0, now),
      Expense('Large', 1000000000, now),
      Expense(' ', 5, now),
      Expense('Future', 5, now.add(const Duration(minutes: 1))),
      Expense('Past', 5, now.subtract(const Duration(days: 1)))
    ]) {
      expect(await book.logExpense(expense), isFalse);
    }
    expect(storage.writes, 0);
    expect(await book.logExpense(Expense('Valid', 5, now)), isTrue);
    expect(
        await book.correctExpense('seed', 0,
            Expense('Future', 5, now.add(const Duration(minutes: 1)))),
        isFalse);
    expect(book.data.active!.spent, 5);
  });

  test('budget corrections use current expenses rather than stale form data',
      () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    final stale = book.data.active!;
    await book.logExpense(Expense('Coffee', 50, now));
    expect(await book.correctBudget(stale.copyWith(funds: 6000)), isTrue);
    expect(book.data.active!.spent, 50);
    expect(
        await book.correctBudget(
            book.data.active!.copyWith(start: DateTime(2026, 10, 24))),
        isFalse);
    expect(book.data.active!.funds, 6000);
  });

  test('product edits preserve past price snapshots', () async {
    final storage =
        MemoryBudgetStorage(BudgetData(budgets: [record()]).encode());
    final book = await open(storage);
    await book.setProducts([const UsualProduct('Coffee', 50)]);
    final product = book.data.products.single;
    await book
        .logExpense(Expense(product.name, product.price, now, product.icon));
    await book.setProducts([const UsualProduct('Coffee', 80)]);
    expect(book.data.active!.expenses.single.amount, 50);
    expect(book.data.products.single.price, 80);
  });

  test('invalid persisted state cannot be replaced by later actions', () async {
    final storage = MemoryBudgetStorage('bad json');
    final book = BudgetBook(storage, now: () => now);
    addTearDown(book.dispose);
    expect(await book.load(), isFalse);
    expect(book.error, contains('Could not load'));
    expect(await book.startBudget(100, now, now, []), isFalse);
    expect(storage.writes, 0);
    expect(storage.value, 'bad json');
  });

  test('saved correction keeps the existing closure-day rule', () {
    final closed = record().copyWith(closedAt: now);
    final laterOnClosureDay = DateTime(2026, 10, 23, 20);
    final nextDay = DateTime(2026, 10, 24, 8);
    final checkTime = DateTime(2026, 10, 25);
    expect(
        ExpenseRules.validate(
            Expense('Correction', 10, laterOnClosureDay), closed, checkTime,
            correction: true),
        isNull);
    expect(
        ExpenseRules.validate(
            Expense('Correction', 10, nextDay), closed, checkTime,
            correction: true),
        isNotNull);
  });
}
