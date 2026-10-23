import '../../domain/models/loan.dart';
import 'dart:convert';
import '../../domain/models/budget_data.dart';

extension BudgetDataJson on BudgetData {
  String encode() => jsonEncode({
        'version': 3,
        'loans': loans.map(_loanJson).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'products': products.map((p) => p.toJson()).toList()
      });
}

class BudgetCodec {
  static BudgetData decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] == 2 || json['version'] == 3) {
      return BudgetData(
          loans: ((json['loans'] ?? []) as List)
              .map((l) => _loanFromJson(l as Map<String, dynamic>))
              .toList(),
          budgets: (json['budgets'] as List)
              .map((b) => _budgetFromJson(b as Map<String, dynamic>))
              .toList(),
          products: (json['products'] as List)
              .map((p) => _productFromJson(p as Map<String, dynamic>))
              .toList());
    }
    final start = dayOnly(DateTime.parse(json['start'] as String));
    final old = ((json['pastExpenses'] ?? []) as List)
        .map((e) => _expenseFromJson(e as Map<String, dynamic>))
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
              .map((e) => _expenseFromJson(e as Map<String, dynamic>))
              .toList()),
    ]);
  }
}

extension UsualProductJson on UsualProduct {
  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'icon': icon};
}

UsualProduct _productFromJson(Map<String, dynamic> json) => UsualProduct(
    json['name'] as String, json['price'] as int, safeIcon(json['icon']));

extension ExpenseJson on Expense {
  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'date': date.toIso8601String(),
        'icon': icon
      };
}

Expense _expenseFromJson(Map<String, dynamic> json) => Expense(
    json['label'] as String,
    json['amount'] as int,
    DateTime.parse(json['date'] as String),
    safeIcon(json['icon']));

extension BudgetRecordJson on BudgetRecord {
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
}

BudgetRecord _budgetFromJson(Map<String, dynamic> json) => BudgetRecord(
    id: json['id'] as String,
    funds: json['funds'] as int,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    expenses: (json['expenses'] as List)
        .map((e) => _expenseFromJson(e as Map<String, dynamic>))
        .toList(),
    closedAt: json['closedAt'] == null
        ? null
        : DateTime.parse(json['closedAt'] as String),
    carriedFrom: json['carriedFrom'] as String?,
    carriedAmount: (json['carriedAmount'] ?? 0) as int,
    legacy: json['legacy'] == true);

Map<String, dynamic> _loanJson(Loan l) => {
      'id': l.id,
      'person': l.person,
      'amount': l.amount,
      'lent': l.lent,
      'date': l.date.toIso8601String(),
      'due': l.due?.toIso8601String(),
      'budgetId': l.budgetId,
      'note': l.note,
      'remind': l.remind,
      'payments': l.payments
          .map((p) => {
                'id': p.id,
                'amount': p.amount,
                'date': p.date.toIso8601String(),
                'budgetId': p.budgetId
              })
          .toList()
    };
Loan _loanFromJson(Map<String, dynamic> j) => Loan(
    id: j['id'] as String,
    person: j['person'] as String,
    amount: j['amount'] as int,
    lent: j['lent'] as bool,
    date: DateTime.parse(j['date'] as String),
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
    budgetId: j['budgetId'] as String?,
    note: j['note'] as String? ?? '',
    remind: j['remind'] as bool? ?? true,
    payments: ((j['payments'] ?? []) as List).map((v) {
      final p = v as Map<String, dynamic>;
      return LoanPayment(
          id: p['id'] as String,
          amount: p['amount'] as int,
          date: DateTime.parse(p['date'] as String),
          budgetId: p['budgetId'] as String?);
    }).toList());
