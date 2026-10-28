import 'budget_data.dart';

class PlanDay {
  const PlanDay(
      {required this.id,
      required this.date,
      required this.amount,
      this.expenseId,
      this.cancelled = false});
  final String id;
  final DateTime date;
  final int amount;
  final String? expenseId;
  final bool cancelled;
  bool get pending => expenseId == null && !cancelled;
  PlanDay resolve({String? expenseId, bool cancelled = false}) => PlanDay(
      id: id,
      date: date,
      amount: amount,
      expenseId: expenseId,
      cancelled: cancelled);
}

class SpendingPlan {
  SpendingPlan(
      {required this.id,
      required this.budgetId,
      required this.label,
      required List<PlanDay> days,
      this.icon = 'banknote',
      this.perDay = false})
      : days = List.unmodifiable(days);
  final String id, budgetId, label, icon;
  final bool perDay;
  final List<PlanDay> days;
  int get reserved =>
      days.where((d) => d.pending).fold(0, (s, d) => s + d.amount);
  bool get complete => days.every((d) => !d.pending);
  bool needsReview(DateTime now, BudgetRecord budget) =>
      !complete &&
      (budget.closedAt != null ||
          days.any((d) => d.pending && daysBetween(d.date, now) > 0));
  SpendingPlan withDays(List<PlanDay> value) => SpendingPlan(
      id: id,
      budgetId: budgetId,
      label: label,
      icon: icon,
      perDay: perDay,
      days: value);
  String? validate(BudgetRecord budget) {
    if (label.trim().isEmpty || label.length > 60) return 'Enter a plan label.';
    if (days.isEmpty ||
        days.length > 3660 ||
        days.map((d) => d.id).toSet().length != days.length ||
        days.map((d) => dayOnly(d.date)).toSet().length != days.length) {
      return 'Choose distinct planned days.';
    }
    if (days.any((d) =>
        d.amount < 1 ||
        d.amount > 999999999 ||
        (!d.cancelled &&
            (daysBetween(budget.start, d.date) < 0 ||
                daysBetween(d.date, budget.end) < 0)))) {
      return 'Each day needs a positive amount and a date within its budget.';
    }
    if (days.fold<int>(0, (s, d) => s + d.amount) > 999999999) {
      return 'The plan amount is too large.';
    }
    return null;
  }

  static List<PlanDay> split(
      List<DateTime> dates, int amount, bool perDay, String prefix) {
    final sorted = dates.map(dayOnly).toSet().toList()..sort();
    if (sorted.isEmpty) return [];
    return [
      for (var i = 0; i < sorted.length; i++)
        PlanDay(
            id: '$prefix-$i',
            date: sorted[i],
            amount: perDay
                ? amount
                : amount ~/ sorted.length +
                    (i < amount % sorted.length ? 1 : 0))
    ];
  }
}
