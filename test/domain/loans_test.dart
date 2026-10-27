import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/domain/models/loan.dart';
import 'package:wafir/domain/rules/loan_reminders.dart';
import 'package:wafir/data/serialization/budget_codec.dart';
import 'package:wafir/presentation/controllers/budget_book.dart';
import '../presentation/budget_book_test.dart' show MemoryBudgetStorage;

void main() {
  final now = DateTime(2026, 10, 23, 15);
  final b = BudgetRecord(
      id: 'b',
      funds: 3000,
      start: DateTime(2026, 10, 23),
      end: DateTime(2026, 11, 21));
  Loan loan(
          {bool lent = true,
          DateTime? due,
          int amount = 500,
          List<LoanPayment> payments = const [],
          String? budgetId = 'b'}) =>
      Loan(
          id: 'l',
          person: 'Amine',
          amount: amount,
          lent: lent,
          date: DateTime(2026, 10, 23, 10),
          due: due,
          budgetId: budgetId,
          payments: payments);
  test(
      'lending changes cash but only reduces planning without an in-period due date',
      () {
    for (final due in [null, DateTime(2026, 11, 22), DateTime(2026, 11, 21)]) {
      final l = loan(due: due);
      final f = BudgetFigures(b, now, loans: [l]);
      expect(f.cash, 2500);
      expect(f.original, 100);
      expect(f.savings, 0);
      expect(f.spentToday, 0);
      expect(f.todayLimit,
          closeTo(due == null || due.isAfter(b.end) ? 2500 / 30 : 100, .0001));
    }
  });
  test(
      'due day inclusive, unpaid balance lowers limits next day; partial return restores cash',
      () {
    final l = loan(due: dayOnly(now), payments: [
      LoanPayment(id: 'p', amount: 200, date: now, budgetId: 'b')
    ]);
    expect(BudgetFigures(b, now, loans: [l]).cash, 2700);
    expect(BudgetFigures(b, now, loans: [l]).todayLimit, 100);
    expect(BudgetFigures(b, DateTime(2026, 10, 24), loans: [l]).todayLimit,
        closeTo(2700 / 29, .0001));
    expect(BudgetFigures(b, now, loans: [l]).tomorrowLimit, 200);
  });
  test('borrowing reserves unpaid debt inside period or without due date', () {
    for (final due in [null, DateTime(2026, 11, 21), DateTime(2026, 11, 22)]) {
      final l = loan(lent: false, due: due);
      final f = BudgetFigures(b, now, loans: [l]);
      expect(f.cash, 3500);
      expect(f.todayLimit,
          closeTo(due != null && due.isAfter(b.end) ? 3500 / 30 : 100, .0001));
      expect(f.savings, 0);
    }
  });
  test('old loan repayment affects only explicitly linked new budget', () {
    final next =
        BudgetRecord(id: 'new', funds: 1000, start: b.start, end: b.end);
    final l = loan(due: b.end, payments: [
      LoanPayment(id: 'p', amount: 100, date: now, budgetId: 'new')
    ]);
    final f = BudgetFigures(next, now, loans: [l]);
    expect(f.cash, 1100);
    expect(f.transfers.expected, 0);
    expect(f.todayLimit, closeTo(1100 / 30, .0001));
  });
  test(
      'loan persistence, corrections, deletion, failures, and normal changes preserve data',
      () async {
    final storage = MemoryBudgetStorage(BudgetData(budgets: [b]).encode());
    final book = BudgetBook(storage, now: () => now);
    addTearDown(book.dispose);
    await book.load();
    expect(await book.saveLoan(loan(due: b.end)), true);
    expect(await book.setProducts([const UsualProduct('Coffee', 50)]), true);
    expect(book.data.loans.length, 1);
    final p = LoanPayment(id: 'p', amount: 200, date: now, budgetId: 'b');
    expect(await book.savePayment('l', p), true);
    expect(
        await book.savePayment(
            'l', LoanPayment(id: 'too-much', amount: 400, date: now)),
        false);
    expect(await book.saveLoan(loan(amount: 100)), false);
    expect(await book.deleteLoan('l'), false);
    final restored = BudgetCodec.decode(storage.value!);
    expect(restored.loans.single.remaining, 300);
    expect(restored.loans.single.payments.single.budgetId, 'b');
    storage.accept = false;
    expect(await book.deletePayment('l', 'p'), false);
    expect(book.data.loans.single.remaining, 300);
    storage.accept = true;
    expect(await book.deletePayment('l', 'p'), true);
    expect(await book.deleteLoan('l'), true);
    expect(book.data.loans, isEmpty);
  });
  test('reminders at local noon, privacy, late entries and cancellation', () {
    final l = loan(due: dayOnly(now));
    final morning = DateTime(2026, 10, 23, 9);
    final schedule = loanReminders([l], morning, {});
    expect(schedule.length, 2);
    expect(schedule.first.when, DateTime(2026, 10, 23, 12));
    expect(schedule.last.when, DateTime(2026, 10, 24, 12));
    expect(schedule.first.body, contains('500 DA'));
    expect(schedule.first.body, isNot(contains('Amine')));
    final late = loanReminders([l], now, {});
    expect(late.first.when, now);
    final handled = schedule.map((r) => r.key).toSet();
    expect(loanReminders([l], now, handled).length, 1);
    expect(loanReminders([l], DateTime(2026, 10, 24, 9), handled).single.when,
        DateTime(2026, 10, 24, 12));
    expect(loanReminders([l], DateTime(2026, 10, 25), handled), isEmpty);
    expect(
        loanReminders(
            [
              loan(
                  payments: [LoanPayment(id: 'p', amount: 500, date: now)],
                  due: l.due)
            ],
            now,
            {}),
        isEmpty);
  });
}
