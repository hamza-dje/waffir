# Graph Report - lib  (2026-10-21)

## Corpus Check
- Corpus is ~4,262 words - fits in a single context window. You may not need a graph.

## Summary
- 156 nodes · 178 edges · 8 communities (7 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- app / main
- app / design / main / onboarding
- app / budget_settings
- app / onboarding
- app / price_check
- app / expense_sheet
- app / main
- app / main

## God Nodes (most connected - your core abstractions)
1. `_BudgetScreenState` - 4 edges
2. `BudgetSettingsPage` - 3 edges
3. `_BudgetSettingsPageState` - 3 edges
4. `ExpenseSheet` - 3 edges
5. `_ExpenseSheetState` - 3 edges
6. `BudgetScreen` - 3 edges
7. `BudgetOnboarding` - 3 edges
8. `_BudgetOnboardingState` - 3 edges
9. `PriceCheck` - 3 edges
10. `_PriceCheckState` - 3 edges

## Surprising Connections (you probably didn't know these)
- `BudgetSettingsPage` --inherits--> `StatefulWidget`  [EXTRACTED]
  budget_settings.dart → None  _Bridges community 2 → community 5_
- `BudgetScreen` --inherits--> `StatefulWidget`  [EXTRACTED]
  main.dart → None  _Bridges community 5 → community 6_
- `BudgetOnboarding` --inherits--> `StatefulWidget`  [EXTRACTED]
  onboarding.dart → None  _Bridges community 5 → community 3_
- `PriceCheck` --inherits--> `StatefulWidget`  [EXTRACTED]
  price_check.dart → None  _Bridges community 5 → community 4_
- `_BudgetScreenState` --inherits--> `State`  [EXTRACTED]
  main.dart → None  _Bridges community 2 → community 6_

## Import Cycles
- None detected.

## Communities (8 total, 1 thin omitted)

### Community 0 - "app / main"
Cohesion: 0.04
Nodes (55): bool get, budget_settings.dart, dart:async, dart:convert, DateTime, expense_sheet.dart, int?, int get (+47 more)

### Community 1 - "app / design / main / onboarding"
Cohesion: 0.09
Nodes (22): Color, background, build, caution, color, hairline, mint, name (+14 more)

### Community 2 - "app / budget_settings"
Cohesion: 0.11
Nodes (19): BudgetPlan, BudgetSettingsPage, _BudgetSettingsPageState, build, createState, dispose, fixed, form (+11 more)

### Community 3 - "app / onboarding"
Cohesion: 0.11
Nodes (19): amount, BudgetOnboarding, _BudgetOnboardingState, build, busy, chooseDate, createState, custom (+11 more)

### Community 4 - "app / price_check"
Cohesion: 0.12
Nodes (16): int price,
  List, allowance, alternatives, build, createState, dispose, expired, onBack (+8 more)

### Community 5 - "app / expense_sheet"
Cohesion: 0.14
Nodes (14): design.dart, amount, build, createState, details, dispose, error, ExpenseSheet (+6 more)

### Community 6 - "app / main"
Cohesion: 0.67
Nodes (3): BudgetScreen, _BudgetScreenState, WidgetsBindingObserver

## Knowledge Gaps
- **106 isolated node(s):** `BudgetPlan`, `target`, `initial`, `form`, `funds` (+101 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 127 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.