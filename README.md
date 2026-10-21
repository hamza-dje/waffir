# Wafir / وفّر

Flutter implementation started from the supplied product and button-system HTML references.

All four approved tickets are implemented: weekly or 30-day budgets, period renewal with retained history, expense logging, fixed costs, savings goals, price checks, and local storage. The supplied DZD SVG is used in the app and launcher icons.

Amounts use whole DZD. The allowance excludes fixed costs, savings, and current-period expenses. Expired periods require renewal before more expenses can be logged. Renewal archives expenses and keeps fixed costs and savings; the new total funds must cover these reserves. Settings and data from version 0.1.0 are retained.

Price checks use three illustrative reference items from the supplied mockup, dated 20 Oct 2026 for Oran. They are marked as examples, not verified market prices or live quotes. Users can enter a quoted price for comparison. Zero and negative allowances are handled without division.

## Run

Use Flutter on PATH, or `C:\Users\hamza\develop\flutter\bin\flutter.bat` on this machine:

```
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

The HTML references are copied under `references/`; source files in Downloads are preserved. Regenerate launcher icons with `flutter test tool/generate_icons.dart`. Language support was excluded from the approved tickets.
