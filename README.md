# Waffir

Flutter budgeting app with Home, History, and Budget tabs. The agreed behavior is in [UX_PLAN.md](UX_PLAN.md).

Onboarding collects inclusive start/end dates, full funds, and optional usual products. Users can log a product with one tap or enter a custom expense. History supports name, amount, and date corrections and confirmed deletion. Budget supports corrections, product management, and stopping and saving a period. A new budget can use the remaining positive balance or a new amount. Completed transfers remain fixed after historical corrections.

Home separates past days, today, and future days. Left today is the large figure. The original daily average stays visible. Today's limit is fixed against spending before today. Calculated savings use completed days. The upcoming average spreads the balance across future days. Tomorrow's limit includes today's result and protects the original average for all later days. Negative amounts remain visible. No future figures are calculated on the last day. Inputs use whole dinars; averages retain precision and display up to two decimal places.

The original Geist, Geist Mono, and Rubik fonts and supplied SVG icons are bundled. The supplied DZD mark appears before every amount at the visual height of the digits, with reduced opacity. Usual-product icons are also faded. Inputs have separate labels and no outlines. The button styles follow the supplied design system.

The previous stored funds, dates, and expenses are preserved. New data uses `budget_state_v2`; the legacy `budget_state` value remains untouched. Fixed-cost deductions, reserved savings, preset products, and price check were removed as agreed. Older archived expenses without recorded budget funds are identified as such.

## Checks and build

```sh
flutter analyze
flutter test
flutter test test/design_capture.dart
flutter build apk --release --split-per-abi --split-debug-info=build/symbols/android
```

The deliverable is `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Keep the symbol files with the release. See [APK_BUILD.md](APK_BUILD.md) for version, size, signature, and native checks.

Visual captures are under `build/ux/`. Refresh the deterministic app graph with `py -3.13 tool/refresh_graph.py`. The supplied HTML files remain in `references/`. No new dependencies were added.
