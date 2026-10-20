# Graph Report - lib  (2026-10-21)

## Corpus Check
- Corpus is ~1,226 words - fits in a single context window. You may not need a graph.

## Summary
Scope: app source only. The graph merges three repeated endpoint pairs with different source locations. See `raw-extraction.json` for all 54 extracted edges. No endpoints are missing.

- 51 nodes · 51 edges · 3 communities (2 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Budget data and actions
- Budget screen state
- Application entry

## God Nodes (most connected - your core abstractions)
1. `BudgetScreen` - 3 edges
2. `_BudgetScreenState` - 3 edges
3. `WafirApp` - 2 edges
4. `Expense` - 1 edges
5. `mint` - 1 edges
6. `background` - 1 edges
7. `surface` - 1 edges
8. `label` - 1 edges
9. `amount` - 1 edges
10. `date` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (3 total, 1 thin omitted)

### Community 0 - "Budget data and actions"
Cohesion: 0.04
Nodes (44): dart:convert, DateTime, FormState, int?, int get, List, allowance, amount (+36 more)

### Community 1 - "Budget screen state"
Cohesion: 0.50
Nodes (4): BudgetScreen, _BudgetScreenState, State, StatefulWidget

## Knowledge Gaps
- **33 isolated node(s):** `Expense`, `mint`, `background`, `surface`, `label` (+28 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 47 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WafirApp` connect `Application entry` to `Budget data and actions`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Why does `BudgetScreen` connect `Budget screen state` to `Budget data and actions`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Why does `_BudgetScreenState` connect `Budget screen state` to `Budget data and actions`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **What connects `Expense`, `mint`, `background` to the rest of the system?**
  _33 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Budget data and actions` be split into smaller, more focused modules?**
  _Cohesion score 0.044444444444444446 - nodes in this community are weakly interconnected._
