import '../models/budget_data.dart';
import '../models/loan.dart';

class LoanReminder {
  const LoanReminder(this.loan, this.when, this.overdue);
  final Loan loan;
  final DateTime when;
  final bool overdue;
  String get key =>
      '${loan.id}/${dayOnly(loan.due!).toIso8601String()}/${overdue ? 'late' : 'due'}';
  String get body => overdue
      ? '${loan.currency.input(loan.remaining)} ${loan.currency.code == 'DZD' ? 'DA' : 'EUR'} ${loan.lent ? 'owed to you is' : 'you owe is'} overdue.'
      : loan.lent
          ? '${loan.currency.input(loan.remaining)} ${loan.currency.code == 'DZD' ? 'DA' : 'EUR'} owed to you is due today.'
          : 'You owe ${loan.currency.input(loan.remaining)} ${loan.currency.code == 'DZD' ? 'DA' : 'EUR'} today.';
}

List<LoanReminder> loanReminders(
    List<Loan> loans, DateTime now, Set<String> handled) {
  final result = <LoanReminder>[];
  for (final l in loans) {
    if (!l.remind || l.due == null || l.remaining <= 0) continue;
    final due = DateTime(l.due!.year, l.due!.month, l.due!.day, 12);
    final late = DateTime(due.year, due.month, due.day + 1, 12);
    final alreadyOverdue = daysBetween(due, now) > 0;
    if (alreadyOverdue) {
      final r = LoanReminder(l, now, true);
      if (!handled.contains(r.key)) {
        result.add(r);
      } else if (late.isAfter(now) && !handled.contains('immediate/${r.key}')) {
        result.add(LoanReminder(l, late, true));
      }
      continue;
    }
    for (final r in [
      LoanReminder(l, due, false),
      LoanReminder(l, late, true)
    ]) {
      if (r.when.isAfter(now) || !handled.contains(r.key)) {
        result.add(
            LoanReminder(l, r.when.isBefore(now) ? now : r.when, r.overdue));
      }
    }
  }
  result.sort((a, b) => a.when.compareTo(b.when));
  return result;
}
