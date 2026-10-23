import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_data.dart';

/// Storage varies between device preferences and deterministic test storage.
abstract interface class BudgetStorage {
  Future<String?> read();
  Future<bool> write(String value);
}

class PreferencesBudgetStorage implements BudgetStorage {
  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('budget_state_v2') ??
        prefs.getString('budget_state');
  }

  @override
  Future<bool> write(String value) async =>
      (await SharedPreferences.getInstance())
          .setString('budget_state_v2', value);
}

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

  static void _validate(BudgetData value) {
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
      final next = raw == null ? BudgetData() : BudgetData.decode(raw);
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
      if (!await storage.write(next.encode())) throw StateError('Save failed');
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
          items[index] = expense;
        }
        return _data.replace(budget.copyWith(expenses: items));
      });

  Future<bool> correctBudget(BudgetRecord correction) => _change(() {
        final current = _record(correction.id);
        final next = current.copyWith(
            funds: correction.funds,
            start: correction.start,
            end: correction.end,
            legacy: false);
        _check(next);
        return _data.replace(next);
      });

  Future<bool> setProducts(List<UsualProduct> products) => _change(() {
        if (products.any((p) =>
            p.name.trim().isEmpty || positiveMoney('${p.price}') != null)) {
          throw const _BudgetRejection(
              'Enter a product name and a positive whole price.');
        }
        return BudgetData(budgets: _data.budgets, products: products);
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
            source.balance > 0 &&
            source.balance == funds;
        final next = BudgetRecord(
            id: '${_now().microsecondsSinceEpoch}-${_data.budgets.length}',
            funds: funds,
            start: start,
            end: end,
            carriedFrom: carried ? source.id : null,
            carriedAmount: carried ? funds : 0);
        _check(next);
        return BudgetData(
            budgets: [..._data.budgets, next], products: products);
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
