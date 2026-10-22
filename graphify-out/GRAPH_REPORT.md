# Graph Report - lib  (2026-10-22)

## Corpus Check
- Corpus is ~5,987 words - fits in a single context window. You may not need a graph.

## Summary
- 222 nodes · 271 edges · 6 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- app / budget_data
- app / budget_data / main
- app / design / editors / main / onboarding
- app / budget_data / editors
- app / onboarding
- app / expense_sheet

## God Nodes (most connected - your core abstractions)
1. `_BudgetScreenState` - 4 edges
2. `BudgetRecord` - 3 edges
3. `BudgetEditor` - 3 edges
4. `_BudgetEditorState` - 3 edges
5. `ExpenseEditor` - 3 edges
6. `_ExpenseEditorState` - 3 edges
7. `ProductEditor` - 3 edges
8. `_ProductEditorState` - 3 edges
9. `ExpenseSheet` - 3 edges
10. `_ExpenseSheetState` - 3 edges

## Surprising Connections (you probably didn't know these)
- `ExpenseSheet` --inherits--> `StatefulWidget`  [EXTRACTED]
  expense_sheet.dart → None  _Bridges community 3 → community 5_
- `BudgetHistoryPage` --inherits--> `StatefulWidget`  [EXTRACTED]
  main.dart → None  _Bridges community 3 → community 1_
- `BudgetOnboarding` --inherits--> `StatefulWidget`  [EXTRACTED]
  onboarding.dart → None  _Bridges community 3 → community 4_

## Import Cycles
- None detected.

## Communities (6 total, 0 thin omitted)

### Community 0 - "app / budget_data"
Cohesion: 0.04
Nodes (48): active, amount, balance, beforeToday, budget, BudgetFigures, budgets, canLog (+40 more)

### Community 1 - "app / budget_data / main"
Cohesion: 0.04
Nodes (46): BudgetData, BudgetRecord? get, dart:async, expense_sheet.dart, budget, BudgetHistoryPage, _BudgetHistoryPageState, budgetPage (+38 more)

### Community 2 - "app / design / editors / main / onboarding"
Cohesion: 0.05
Nodes (44): Color, background, build, caution, color, controller, currency, CurrencySymbol (+36 more)

### Community 3 - "app / budget_data / editors"
Cohesion: 0.05
Nodes (42): BudgetRecord, Expense, UsualProduct, amount, budget, BudgetEditor, _BudgetEditorState, build (+34 more)

### Community 4 - "app / onboarding"
Cohesion: 0.09
Nodes (23): budget_data.dart, DateTime, editors.dart, int?, List, amount, BudgetOnboarding, _BudgetOnboardingState (+15 more)

### Community 5 - "app / expense_sheet"
Cohesion: 0.15
Nodes (13): design.dart, amount, build, createState, details, dispose, error, ExpenseSheet (+5 more)

## Knowledge Gaps
- **154 isolated node(s):** `BudgetFigures`, `productIcons`, `name`, `price`, `icon` (+149 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 174 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)