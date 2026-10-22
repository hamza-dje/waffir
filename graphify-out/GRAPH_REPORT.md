# Graph Report - lib  (2026-10-22)

## Corpus Check
- Corpus is ~6,360 words - fits in a single context window. You may not need a graph.

## Summary
- 230 nodes · 285 edges · 7 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- app / budget_data
- app / budget_data / main
- app / expense_sheet / onboarding
- app / budget_data / editors
- app / design
- app / editors / expense_sheet / main / onboarding
- app / design / editors / main / onboarding

## God Nodes (most connected - your core abstractions)
1. `_BudgetScreenState` - 4 edges
2. `Expense` - 3 edges
3. `BudgetRecord` - 3 edges
4. `BudgetEditor` - 3 edges
5. `_BudgetEditorState` - 3 edges
6. `ExpenseEditor` - 3 edges
7. `_ExpenseEditorState` - 3 edges
8. `ProductEditor` - 3 edges
9. `_ProductEditorState` - 3 edges
10. `ExpenseSheet` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (7 total, 0 thin omitted)

### Community 0 - "app / budget_data"
Cohesion: 0.04
Nodes (48): active, amount, balance, beforeToday, budget, BudgetFigures, budgets, canLog (+40 more)

### Community 1 - "app / budget_data / main"
Cohesion: 0.05
Nodes (43): BudgetData, BudgetRecord? get, dart:async, expense_sheet.dart, budget, budgetPage, build, carrySource (+35 more)

### Community 2 - "app / expense_sheet / onboarding"
Cohesion: 0.06
Nodes (35): budget_data.dart, DateTime, design.dart, editors.dart, amount, build, createState, details (+27 more)

### Community 3 - "app / budget_data / editors"
Cohesion: 0.06
Nodes (35): BudgetRecord, Expense, UsualProduct, amount, budget, build, busy, confirmAction (+27 more)

### Community 4 - "app / design"
Cohesion: 0.06
Nodes (34): Color, background, build, caution, color, controller, currency, data (+26 more)

### Community 5 - "app / editors / expense_sheet / main / onboarding"
Cohesion: 0.16
Nodes (17): BudgetEditor, _BudgetEditorState, ExpenseEditor, _ExpenseEditorState, ProductEditor, _ProductEditorState, ExpenseSheet, _ExpenseSheetState (+9 more)

### Community 6 - "app / design / editors / main / onboarding"
Cohesion: 0.17
Nodes (12): CurrencySymbol, CurrencyText, LabeledField, SourceIcon, DateControl, ExpenseIcons, ExpenseTime, ProductList (+4 more)

## Knowledge Gaps
- **159 isolated node(s):** `BudgetFigures`, `productIcons`, `name`, `price`, `icon` (+154 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 179 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)