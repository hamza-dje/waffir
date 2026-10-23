import 'dart:convert';

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

class UsualProduct {
  const UsualProduct(this.name, this.price, [this.icon = 'banknote']);
  final String name;
  final int price;
  final String icon;
  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'icon': icon};
  factory UsualProduct.fromJson(Map<String, dynamic> json) => UsualProduct(
      json['name'] as String, json['price'] as int, safeIcon(json['icon']));
}

class Expense {
  const Expense(this.label, this.amount, this.date, [this.icon = 'banknote']);
  final String label;
  final int amount;
  final DateTime date;
  final String icon;
  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'date': date.toIso8601String(),
        'icon': icon
      };
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
      json['label'] as String,
      json['amount'] as int,
      DateTime.parse(json['date'] as String),
      safeIcon(json['icon']));
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
  Map<String, dynamic> toJson() => {
        'id': id,
        'funds': funds,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'closedAt': closedAt?.toIso8601String(),
        'carriedFrom': carriedFrom,
        'carriedAmount': carriedAmount,
        'legacy': legacy
      };
  factory BudgetRecord.fromJson(Map<String, dynamic> json) => BudgetRecord(
      id: json['id'] as String,
      funds: json['funds'] as int,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      expenses: (json['expenses'] as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      carriedFrom: json['carriedFrom'] as String?,
      carriedAmount: (json['carriedAmount'] ?? 0) as int,
      legacy: json['legacy'] == true);
}

class BudgetFigures {
  BudgetFigures(this.budget, DateTime now)
      : date = dayOnly(budget.closedAt ?? now);
  final BudgetRecord budget;
  final DateTime date;
  int get completed => daysBetween(budget.start, date).clamp(0, budget.days);
  int get remainingDays => budget.days - completed;
  int get beforeToday => budget.expenses
      .where((e) => daysBetween(e.date, date) > 0)
      .fold(0, (sum, e) => sum + e.amount);
  int get spentToday => budget.expenses
      .where((e) => daysBetween(e.date, date) == 0)
      .fold(0, (sum, e) => sum + e.amount);
  double get original => budget.funds / budget.days;
  double? get todayLimit =>
      budget.canLog(date) ? (budget.funds - beforeToday) / remainingDays : null;
  double? get leftToday => todayLimit == null ? null : todayLimit! - spentToday;
  double get savings => original * completed - beforeToday;
  double? get upcoming => budget.canLog(date) && remainingDays > 1
      ? budget.balance / (remainingDays - 1)
      : null;
  double? get tomorrowLimit => budget.canLog(date) && remainingDays > 1
      ? original + savings + original - spentToday
      : null;
}

class BudgetData {
  BudgetData(
      {List<BudgetRecord> budgets = const [],
      List<UsualProduct> products = const []})
      : budgets = List.unmodifiable(budgets),
        products = List.unmodifiable(products);
  final List<BudgetRecord> budgets;
  final List<UsualProduct> products;
  BudgetRecord? get active =>
      budgets.where((b) => b.closedAt == null).firstOrNull;
  BudgetData replace(BudgetRecord record) => BudgetData(
      products: products,
      budgets: budgets.map((b) => b.id == record.id ? record : b).toList());
  String encode() => jsonEncode({
        'version': 2,
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'products': products.map((p) => p.toJson()).toList()
      });
  factory BudgetData.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] == 2) {
      return BudgetData(
          budgets: (json['budgets'] as List)
              .map((b) => BudgetRecord.fromJson(b as Map<String, dynamic>))
              .toList(),
          products: (json['products'] as List)
              .map((p) => UsualProduct.fromJson(p as Map<String, dynamic>))
              .toList());
    }
    final start = dayOnly(DateTime.parse(json['start'] as String));
    final old = ((json['pastExpenses'] ?? []) as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return BudgetData(budgets: [
      if (old.isNotEmpty)
        BudgetRecord(
            id: 'legacy-history',
            funds: 0,
            start: dayOnly(old.first.date),
            end: dayOnly(old.last.date),
            closedAt: old.last.date,
            expenses: old,
            legacy: true),
      BudgetRecord(
          id: 'legacy-current',
          funds: json['budget'] as int,
          start: start,
          end: DateTime(
              start.year, start.month, start.day + (json['days'] as int) - 1),
          expenses: (json['expenses'] as List)
              .map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList()),
    ]);
  }
}
