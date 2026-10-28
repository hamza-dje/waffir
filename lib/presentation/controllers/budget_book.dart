import '../../domain/models/app_currency.dart';
import '../../domain/models/spending_plan.dart';
import '../../domain/models/loan.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/rules/expense_rules.dart';
import '../../domain/repositories/budget_storage.dart';

/// Owns budget changes, their validation, and durable-before-visible writes.
class BudgetBook extends ChangeNotifier {
  BudgetBook(this.storage, {DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final BudgetStorage storage;
  final DateTime Function() _now;
  BudgetData _data = BudgetData();
  BudgetData get data => _data;
  bool _loaded = false, _saving = false, _disposed = false;
  String? _error;
  bool get loaded => _loaded;
  bool get saving => _saving;
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _validate(BudgetData value) {
    if (value.plans.map((p) => p.id).toSet().length != value.plans.length ||
        value.plans.any((p) {
          final budget =
              value.budgets.where((b) => b.id == p.budgetId).firstOrNull;
          return budget == null ||
              p.validate(budget) != null ||
              p.days.any((d) =>
                  d.expenseId != null &&
                  !budget.expenses.any((e) => e.id == d.expenseId));
        })) {
      throw const FormatException('Invalid plans');
    }
    if (value.loans.map((l) => l.id).toSet().length != value.loans.length ||
        value.loans.any((l) =>
            l.validate(_now()) != null ||
            [l.budgetId, ...l.payments.map((p) => p.budgetId)].any(
                (id) => id != null && !value.budgets.any((b) => b.id == id)))) {
      throw const FormatException('Invalid loans');
    }
    for (final loan in value.loans) {
      for (final id in [
        loan.budgetId,
        ...loan.payments.map((p) => p.budgetId)
      ]) {
        if (id != null &&
            value.budgets.firstWhere((b) => b.id == id).currency !=
                loan.currency) {
          throw const _BudgetRejection('Choose a budget in the same currency.');
        }
      }
    }
    if (value.budgets.where((b) => b.closedAt == null).length > 1 ||
        value.budgets.map((b) => b.id).toSet().length != value.budgets.length ||
        value.budgets.any((b) => b.validate() != null) ||
        value.products.any((p) =>
            p.name.trim().isEmpty || positiveMoney('${p.price}') != null)) {
      throw const FormatException('Invalid budget data');
    }
  }

  Future<bool> load() async {
    if (_loaded || _saving) return false;
    _saving = true;
    _notify();
    try {
      final raw = await storage.read();
      final next = raw ?? BudgetData();
      _validate(next);
      _data = next;
      _loaded = true;
      _error = null;
      return true;
    } catch (_) {
      _error =
          'Could not load your budget. Restart the app. Your saved data has not been changed.';
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  Future<bool> _change(BudgetData Function() change) async {
    // A rejected concurrent action must not replace the in-flight result.
    if (!_loaded || _saving || _disposed) return false;
    _saving = true;
    _error = null;
    _notify();
    try {
      final next = change();
      _validate(next);
      if (!await storage.write(next)) throw StateError('Save failed');
      _data = next;
      return true;
    } on _BudgetRejection catch (rejection) {
      _error = rejection.message;
      return false;
    } catch (_) {
      _error = 'Could not save. Please try again.';
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  BudgetRecord _record(String id) =>
      _data.budgets.firstWhere((b) => b.id == id);
  void _check(BudgetRecord record) {
    final invalid = record.validate();
    if (invalid != null) throw _BudgetRejection(invalid);
  }

  Future<bool> logExpense(Expense expense) => _change(() {
        final active = _data.active;
        if (active == null) {
          throw const _BudgetRejection('Start a budget first.');
        }
        final invalid = ExpenseRules.validate(expense, active, _now());
        if (invalid != null) throw _BudgetRejection(invalid);
        return _data
            .replace(active.copyWith(expenses: [...active.expenses, expense]));
      });

  Future<bool> correctExpense(String id, int index, Expense? expense) =>
      _change(() {
        final budget = _record(id);
        if (index < 0 || index >= budget.expenses.length) {
          throw const _BudgetRejection('This expense is no longer available.');
        }
        if (expense != null) {
          final invalid =
              ExpenseRules.validate(expense, budget, _now(), correction: true);
          if (invalid != null) throw _BudgetRejection(invalid);
        }
        final items = [...budget.expenses];
        if (expense == null) {
          items.removeAt(index);
        } else {
          items[index] = Expense(
              expense.label,
              expense.amount,
              expense.date,
              expense.icon,
              budget.expenses[index].id,
              budget.expenses[index].planned);
        }
        final oldId = budget.expenses[index].id;
        final changed = _data.replace(budget.copyWith(expenses: items));
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            budgets: changed.budgets,
            loans: changed.loans,
            products: changed.products,
            plans: [
              for (final p in changed.plans)
                expense == null && oldId != null
                    ? p.withDays([
                        for (final d in p.days)
                          d.expenseId == oldId ? d.resolve() : d
                      ])
                    : p
            ]);
      });

  Future<bool> correctBudget(BudgetRecord correction) => _change(() {
        final current = _record(correction.id);
        final next = current.copyWith(
            funds: correction.funds,
            start: correction.start,
            end: correction.end,
            legacy: false);
        _check(next);
        for (final p in _data.plans.where((p) => p.budgetId == next.id)) {
          final invalid = p.validate(next);
          if (invalid != null) {
            throw const _BudgetRejection(
                'Move or cancel plans outside the new budget dates first.');
          }
        }
        return _data.replace(next);
      });

  Future<bool> setCurrency(AppCurrency currency) => _change(() => BudgetData(
      defaultCurrency: currency,
      budgets: _data.budgets,
      products: _data.products,
      loans: _data.loans,
      plans: _data.plans));

  Future<bool> setProducts(List<UsualProduct> products) => _change(() {
        if (products.any((p) =>
            p.name.trim().isEmpty || positiveMoney('${p.price}') != null)) {
          throw const _BudgetRejection(
              'Enter a product name and a positive whole price.');
        }
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            plans: _data.plans,
            budgets: _data.budgets,
            products: [
              ..._data.products.where((p) =>
                  !products.any((n) => n.currency == p.currency) &&
                  p.currency !=
                      (_data.active?.currency ?? _data.defaultCurrency)),
              ...products
            ],
            loans: _data.loans);
      });

  Future<bool> startBudget(
          int funds, DateTime start, DateTime end, List<UsualProduct> products,
          {String? carryFrom}) =>
      _change(() {
        if (_data.active != null) {
          throw const _BudgetRejection('Stop the active budget first.');
        }
        final source = carryFrom == null ? null : _record(carryFrom);
        final carried = source != null &&
            source.closedAt != null &&
            source.currency == _data.defaultCurrency &&
            cashBalance(source) > 0 &&
            cashBalance(source) == funds;
        final next = BudgetRecord(
            id: '${_now().microsecondsSinceEpoch}-${_data.budgets.length}',
            currency: _data.defaultCurrency,
            funds: funds,
            start: start,
            end: end,
            carriedFrom: carried ? source.id : null,
            carriedAmount: carried ? funds : 0);
        _check(next);
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            plans: _data.plans,
            budgets: [..._data.budgets, next],
            products: [
              ..._data.products.where((p) =>
                  !products.any((n) => n.currency == p.currency) &&
                  p.currency !=
                      (_data.active?.currency ?? _data.defaultCurrency)),
              ...products
            ],
            loans: _data.loans);
      });

  int cashBalance(BudgetRecord b) =>
      b.balance + LoanFigures(b, _data.loans, b.closedAt ?? _now()).cashChange;

  Future<bool> saveLoan(Loan loan) => _change(() {
        final old = _data.loans.where((l) => l.id == loan.id).firstOrNull;
        if (old != null && old.currency != loan.currency) {
          throw const _BudgetRejection('A saved loan keeps its currency.');
        }
        if (old != null && old.payments.isNotEmpty && old.lent != loan.lent) {
          throw const _BudgetRejection(
              'Delete the payment records before changing the loan direction.');
        }
        final next = old == null ? loan : loan.withPayments(old.payments);
        final error = next.validate(_now());
        if (error != null) throw _BudgetRejection(error);
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            plans: _data.plans,
            budgets: _data.budgets,
            products: _data.products,
            loans: [
              for (final l in _data.loans)
                if (l.id != next.id) l,
              next
            ]);
      });

  Future<bool> deleteLoan(String id) => _change(() {
        final loan = _data.loans.firstWhere((l) => l.id == id);
        if (loan.payments.isNotEmpty) {
          throw const _BudgetRejection('Delete the payment records first.');
        }
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            plans: _data.plans,
            budgets: _data.budgets,
            products: _data.products,
            loans: _data.loans.where((l) => l.id != id).toList());
      });

  Future<bool> savePayment(String loanId, LoanPayment payment) => _change(() {
        final loan = _data.loans.firstWhere((l) => l.id == loanId);
        final next = loan.withPayments([
          for (final p in loan.payments)
            if (p.id != payment.id) p,
          payment
        ]);
        final error = next.validate(_now());
        if (error != null) throw _BudgetRejection(error);
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            plans: _data.plans,
            budgets: _data.budgets,
            products: _data.products,
            loans: [for (final l in _data.loans) l.id == loanId ? next : l]);
      });

  Future<bool> deletePayment(String loanId, String paymentId) => _change(() {
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            plans: _data.plans,
            budgets: _data.budgets,
            products: _data.products,
            loans: [
              for (final l in _data.loans)
                l.id == loanId
                    ? l.withPayments(
                        l.payments.where((p) => p.id != paymentId).toList())
                    : l
            ]);
      });

  BudgetFigures figures(BudgetRecord budget) =>
      BudgetFigures(budget, _now(), loans: _data.loans, plans: _data.plans);

  Future<bool> savePlan(SpendingPlan plan) => _change(() {
        final old = _data.plans.where((p) => p.id == plan.id).firstOrNull;
        final budget = _record(plan.budgetId);
        if (budget.closedAt != null) {
          throw const _BudgetRejection('Choose the active budget.');
        }
        final invalid = plan.validate(budget);
        if (invalid != null) throw _BudgetRejection(invalid);
        if (old != null && _record(old.budgetId).currency != budget.currency) {
          throw const _BudgetRejection('Move plans within the same currency.');
        }
        final moving = old != null && old.budgetId != plan.budgetId;
        if (moving && plan.days.any((d) => !d.pending)) {
          throw const _BudgetRejection('Move unfinished days only.');
        }
        if (old != null && !moving) {
          for (final day in old.days.where((d) => !d.pending)) {
            if (old.budgetId != plan.budgetId ||
                !plan.days.any((d) =>
                    d.id == day.id &&
                    d.amount == day.amount &&
                    d.date == day.date &&
                    d.expenseId == day.expenseId &&
                    d.cancelled == day.cancelled)) {
              throw const _BudgetRejection(
                  'Completed days cannot be changed or moved.');
            }
          }
        }
        for (final d in plan.days.where((d) => d.pending)) {
          final unchanged = !moving &&
              (old?.days.any((a) => a.id == d.id && a.date == d.date) ?? false);
          if (!unchanged && daysBetween(_now(), d.date) < 0) {
            throw const _BudgetRejection('Choose today or a future day.');
          }
        }
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            budgets: _data.budgets,
            products: _data.products,
            loans: _data.loans,
            plans: [
              for (final p in _data.plans)
                if (p.id != plan.id) p,
              if (moving && old.days.any((d) => !d.pending))
                old.withDays(old.days.where((d) => !d.pending).toList()),
              if (moving && old.days.any((d) => !d.pending))
                SpendingPlan(
                    id: '${plan.id}-moved-${_now().microsecondsSinceEpoch}',
                    budgetId: plan.budgetId,
                    label: plan.label,
                    icon: plan.icon,
                    mode: plan.mode,
                    days: plan.days)
              else
                plan
            ]);
      });

  Future<bool> deletePlan(String id) => _change(() => BudgetData(
      defaultCurrency: _data.defaultCurrency,
      budgets: _data.budgets,
      products: _data.products,
      loans: _data.loans,
      plans: _data.plans.where((p) => p.id != id).toList()));

  Future<bool> cancelPlanDay(String planId, String dayId) => _change(() {
        final plan = _data.plans.firstWhere((p) => p.id == planId);
        final day = plan.days.firstWhere((d) => d.id == dayId);
        if (!day.pending) {
          throw const _BudgetRejection('This day is already resolved.');
        }
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            budgets: _data.budgets,
            products: _data.products,
            loans: _data.loans,
            plans: [
              for (final p in _data.plans)
                p.id == planId
                    ? p.withDays([
                        for (final d in p.days)
                          d.id == dayId ? d.resolve(cancelled: true) : d
                      ])
                    : p
            ]);
      });

  Future<bool> recordPlanDay(String planId, String dayId, Expense expense) =>
      _change(() {
        final plan = _data.plans.firstWhere((p) => p.id == planId);
        final day = plan.days.firstWhere((d) => d.id == dayId);
        final budget = _record(plan.budgetId);
        if (!day.pending ||
            daysBetween(_now(), day.date) > 0 ||
            budget.closedAt != null) {
          throw const _BudgetRejection(
              'Record this day when due in an active budget.');
        }
        final invalid =
            ExpenseRules.validate(expense, budget, _now(), correction: true);
        if (invalid != null) throw _BudgetRejection(invalid);
        final id = 'plan-$planId-$dayId';
        final changed = _data.replace(budget.copyWith(expenses: [
          ...budget.expenses,
          Expense(expense.label, expense.amount, expense.date, expense.icon, id,
              true)
        ]));
        return BudgetData(
            defaultCurrency: _data.defaultCurrency,
            budgets: changed.budgets,
            products: _data.products,
            loans: _data.loans,
            plans: [
              for (final p in _data.plans)
                p.id == planId
                    ? p.withDays([
                        for (final d in p.days)
                          d.id == dayId ? d.resolve(expenseId: id) : d
                      ])
                    : p
            ]);
      });

  Future<bool> stopBudget(String id) => _change(() {
        final active = _data.active;
        if (active == null || active.id != id) {
          throw const _BudgetRejection('This budget is no longer active.');
        }
        return _data.replace(active.copyWith(closedAt: _now()));
      });
}

class _BudgetRejection implements Exception {
  const _BudgetRejection(this.message);
  final String message;
}
