import 'loan.dart';

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

const productIcons = [
  'banknote',
  'coffee',
  'sandwich',
  'bus',
  'droplet',
  'utensils',
  'egg',
  'leaf',
  'home',
  'calendar',
  'sun'
];
String safeIcon(Object? name) =>
    productIcons.contains(name) ? name as String : 'banknote';

class UsualProduct {
  const UsualProduct(this.name, this.price, [this.icon = 'banknote']);
  final String name;
  final int price;
  final String icon;
}

class Expense {
  const Expense(this.label, this.amount, this.date, [this.icon = 'banknote']);
  final String label;
  final int amount;
  final DateTime date;
  final String icon;
}

class BudgetRecord {
  BudgetRecord(
      {required this.id,
      required this.funds,
      required this.start,
      required this.end,
      List<Expense> expenses = const [],
      this.closedAt,
      this.carriedFrom,
      this.carriedAmount = 0,
      this.legacy = false})
      : expenses = List.unmodifiable(expenses);
  final String id;
  final int funds;
  final DateTime start;
  final DateTime end;
  final List<Expense> expenses;
  final DateTime? closedAt;
  final String? carriedFrom;
  final int carriedAmount;
  // Earlier app versions stored archived expenses without their budget amount.
  final bool legacy;
  int get days => daysBetween(start, end) + 1;
  int get spent => expenses.fold(0, (sum, e) => sum + e.amount);
  int get balance => funds - spent;
  bool canLog(DateTime now) =>
      closedAt == null &&
      daysBetween(start, now) >= 0 &&
      daysBetween(now, end) >= 0;
  String? validate() {
    if ((!legacy && funds <= 0) || funds > 999999999) {
      return 'Enter a positive budget in whole dinars.';
    }
    if (days < 1 || days > 3660) {
      return 'Choose between 1 and 3660 budget days.';
    }
    if (expenses.any((e) =>
        e.amount <= 0 ||
        e.label.trim().isEmpty ||
        daysBetween(start, e.date) < 0 ||
        daysBetween(e.date, end) < 0)) {
      return 'These dates exclude an expense. Correct that expense first.';
    }
    return null;
  }

  BudgetRecord copyWith(
          {int? funds,
          DateTime? start,
          DateTime? end,
          List<Expense>? expenses,
          DateTime? closedAt,
          bool? legacy}) =>
      BudgetRecord(
          id: id,
          funds: funds ?? this.funds,
          start: start ?? this.start,
          end: end ?? this.end,
          expenses: expenses ?? this.expenses,
          closedAt: closedAt ?? this.closedAt,
          legacy: legacy ?? this.legacy,
          carriedFrom: carriedFrom,
          carriedAmount: carriedAmount);
}

class BudgetFigures {
  BudgetFigures(this.budget, DateTime now, {this.loans = const []})
      : date = dayOnly(budget.closedAt ?? now);
  final BudgetRecord budget;
  final List<Loan> loans;
  final DateTime date;
  LoanFigures get transfers => LoanFigures(budget, loans, date);
  int get cash => budget.balance + transfers.cashChange;
  int get completed => daysBetween(budget.start, date).clamp(0, budget.days);
  int get remainingDays => budget.days - completed;
  int get beforeToday => budget.expenses
      .where((e) => daysBetween(e.date, date) > 0)
      .fold(0, (sum, e) => sum + e.amount);
  int get spentToday => budget.expenses
      .where((e) => daysBetween(e.date, date) == 0)
      .fold(0, (sum, e) => sum + e.amount);
  double get original => budget.funds / budget.days;
  double? get todayLimit => budget.canLog(date)
      ? (budget.funds - beforeToday + transfers.adjustment) / remainingDays
      : null;
  double? get leftToday => todayLimit == null ? null : todayLimit! - spentToday;
  double get savings => original * completed - beforeToday;
  double? get upcoming => budget.canLog(date) && remainingDays > 1
      ? (budget.balance + transfers.adjustment) / (remainingDays - 1)
      : null;
  double? get tomorrowLimit => budget.canLog(date) && remainingDays > 1
      ? original +
          savings +
          original -
          spentToday +
          LoanFigures(
                  budget, loans, DateTime(date.year, date.month, date.day + 1))
              .adjustment
      : null;
}

class BudgetData {
  BudgetData(
      {List<BudgetRecord> budgets = const [],
      List<UsualProduct> products = const [],
      List<Loan> loans = const []})
      : budgets = List.unmodifiable(budgets),
        products = List.unmodifiable(products),
        loans = List.unmodifiable(loans);
  final List<BudgetRecord> budgets;
  final List<UsualProduct> products;
  final List<Loan> loans;
  BudgetRecord? get active =>
      budgets.where((b) => b.closedAt == null).firstOrNull;
  BudgetData replace(BudgetRecord record) => BudgetData(
      products: products,
      loans: loans,
      budgets: budgets.map((b) => b.id == record.id ? record : b).toList());
}
