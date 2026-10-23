import 'budget_data.dart';

class LoanPayment {
  const LoanPayment(
      {required this.id,
      required this.amount,
      required this.date,
      this.budgetId});
  final String id;
  final int amount;
  final DateTime date;
  final String? budgetId;
}

class Loan {
  Loan(
      {required this.id,
      required this.person,
      required this.amount,
      required this.lent,
      required this.date,
      this.due,
      this.budgetId,
      this.note = '',
      this.remind = true,
      List<LoanPayment> payments = const []})
      : payments = List.unmodifiable(payments);
  final String id, person, note;
  final int amount;
  final bool lent, remind;
  final DateTime date;
  final DateTime? due;
  final String? budgetId;
  final List<LoanPayment> payments;
  int get paid => payments.fold(0, (s, p) => s + p.amount);
  int get remaining => amount - paid;
  int remainingAt(DateTime day) =>
      amount -
      payments
          .where((p) => daysBetween(p.date, day) >= 0)
          .fold<int>(0, (s, p) => s + p.amount);
  bool overdue(DateTime now) =>
      remaining > 0 && due != null && daysBetween(due!, now) > 0;
  Loan withPayments(List<LoanPayment> value) => Loan(
      id: id,
      person: person,
      amount: amount,
      lent: lent,
      date: date,
      due: due,
      budgetId: budgetId,
      note: note,
      remind: remind,
      payments: value);
  String? validate(DateTime now) {
    if (person.trim().isEmpty || person.length > 60) {
      return 'Enter a person name (up to 60 characters).';
    }
    if (amount <= 0 || amount > 999999999) {
      return 'Enter a positive amount in whole dinars.';
    }
    if (date.isAfter(now)) return 'The loan date cannot be in the future.';
    if (due != null && daysBetween(date, due!) < 0) {
      return 'The due date cannot be before the loan date.';
    }
    if (payments.map((p) => p.id).toSet().length != payments.length ||
        payments.any((p) =>
            p.amount <= 0 ||
            p.amount > 999999999 ||
            p.date.isBefore(date) ||
            p.date.isAfter(now)) ||
        remaining < 0) {
      return 'Check payment amounts and dates. Payments cannot exceed the loan.';
    }
    return null;
  }
}

/// Cash movements and planning reserves are distinct from expenses.
class LoanFigures {
  LoanFigures(this.budget, this.loans, this.date);
  final BudgetRecord budget;
  final List<Loan> loans;
  final DateTime date;
  int get cashChange {
    var total = 0;
    for (final l in loans) {
      if (l.budgetId == budget.id && daysBetween(l.date, date) >= 0) {
        total += l.lent ? -l.amount : l.amount;
      }
      for (final p in l.payments) {
        if (p.budgetId == budget.id && daysBetween(p.date, date) >= 0) {
          total += l.lent ? p.amount : -p.amount;
        }
      }
    }
    return total;
  }

  int get expected => loans
      .where((l) =>
          l.lent &&
          l.budgetId == budget.id &&
          daysBetween(l.date, date) >= 0 &&
          l.due != null &&
          daysBetween(date, l.due!) >= 0 &&
          daysBetween(l.due!, budget.end) >= 0)
      .fold(0, (s, l) => s + l.remainingAt(date));
  int get reserved => loans
      .where((l) =>
          !l.lent &&
          l.budgetId == budget.id &&
          daysBetween(l.date, date) >= 0 &&
          (l.due == null || daysBetween(l.due!, budget.end) >= 0))
      .fold(0, (s, l) => s + l.remainingAt(date));
  int get adjustment => cashChange + expected - reserved;
}
