# Graph Report - lib  (2026-10-21)

## Corpus Check
- Corpus is ~2,677 words - fits in a single context window. You may not need a graph.

## Summary
- 104 nodes · 112 edges · 6 communities (4 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Budget periods and storage
- Budget settings form
- Price checks and alternatives
- Stateful app screens
- Settings navigation
- Application entry

## God Nodes (most connected - your core abstractions)
1. `_BudgetScreenState` - 4 edges
2. `BudgetSettingsPage` - 3 edges
3. `_BudgetSettingsPageState` - 3 edges
4. `BudgetScreen` - 3 edges
5. `PriceCheck` - 3 edges
6. `_PriceCheckState` - 3 edges
7. `WafirApp` - 2 edges
8. `editBudget` - 2 edges
9. `BudgetPlan` - 1 edges
10. `target` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (6 total, 2 thin omitted)

### Community 0 - "Budget periods and storage"
Cohesion: 0.03
Nodes (58): bool get, budget_settings.dart, dart:async, dart:convert, DateTime, int?, int get, List (+50 more)

### Community 1 - "Budget settings form"
Cohesion: 0.12
Nodes (15): BudgetPlan, build, createState, dispose, fixed, form, funds, goal (+7 more)

### Community 2 - "Price checks and alternatives"
Cohesion: 0.12
Nodes (15): int price,
  List, package:flutter/material.dart, allowance, alternatives, build, createState, dispose, expired (+7 more)

### Community 3 - "Stateful app screens"
Cohesion: 0.28
Nodes (9): BudgetSettingsPage, _BudgetSettingsPageState, BudgetScreen, _BudgetScreenState, PriceCheck, _PriceCheckState, State, StatefulWidget (+1 more)

## Knowledge Gaps
- **69 isolated node(s):** `BudgetPlan`, `target`, `initial`, `form`, `funds` (+64 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 88 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_BudgetScreenState` connect `Stateful app screens` to `Budget periods and storage`?**
  _High betweenness centrality (0.042) - this node is a cross-community bridge._
- **Why does `BudgetScreen` connect `Stateful app screens` to `Budget periods and storage`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `WafirApp` connect `Application entry` to `Budget periods and storage`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `BudgetPlan`, `target`, `initial` to the rest of the system?**
  _69 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Budget periods and storage` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **Should `Budget settings form` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Price checks and alternatives` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._