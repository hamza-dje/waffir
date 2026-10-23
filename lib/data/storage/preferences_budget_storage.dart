import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/repositories/budget_storage.dart';
import '../serialization/budget_codec.dart';

class PreferencesBudgetStorage implements BudgetStorage {
  const PreferencesBudgetStorage();
  @override
  Future<BudgetData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString('budget_state_v2') ?? prefs.getString('budget_state');
    return raw == null ? null : BudgetCodec.decode(raw);
  }

  @override
  Future<bool> write(BudgetData value) async =>
      (await SharedPreferences.getInstance())
          .setString('budget_state_v2', value.encode());
}
