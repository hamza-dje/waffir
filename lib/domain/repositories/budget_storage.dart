import '../models/budget_data.dart';

/// The budget book reads and writes complete domain state, not encoded JSON.
abstract interface class BudgetStorage {
  Future<BudgetData?> read();
  Future<bool> write(BudgetData value);
}
