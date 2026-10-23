import '../models/budget_data.dart';

String? positiveMoney(String? value) {
  final amount = int.tryParse(value ?? '');
  return amount == null || amount <= 0 || amount > 999999999
      ? 'Enter a positive whole amount'
      : null;
}

/// The same rules apply to manual entry, product taps, and corrections.
class ExpenseRules {
  static String? nameError(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter a name' : null;

  static String? validate(Expense expense, BudgetRecord budget, DateTime now,
      {bool correction = false}) {
    final amountError = positiveMoney('${expense.amount}');
    if (amountError != null) return amountError;
    final invalidName = nameError(expense.label);
    if (invalidName != null) return invalidName;
    if (expense.date.isAfter(now)) return 'Choose a time before now';
    if (daysBetween(budget.start, expense.date) < 0 ||
        daysBetween(expense.date, budget.end) < 0 ||
        (correction &&
            budget.closedAt != null &&
            daysBetween(expense.date, budget.closedAt!) < 0)) {
      return 'Choose an expense date within this budget.';
    }
    if (!correction && !budget.canLog(now)) {
      return 'This budget is not active today.';
    }
    return null;
  }
}
