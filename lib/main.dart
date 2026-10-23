import 'package:flutter/material.dart';
import 'data/storage/preferences_budget_storage.dart';
import 'presentation/app.dart';

void main() => runApp(const WafirApp(storage: PreferencesBudgetStorage()));
