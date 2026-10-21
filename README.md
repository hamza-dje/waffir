# Waffir / وفّر

Flutter implementation started from the supplied product and button-system HTML references.

All four approved tickets are implemented: weekly, 30-day, or custom end-date budgets, period renewal with retained history, expense logging, fixed costs, savings goals, price checks, and local storage. The supplied DZD SVG is used in the launcher icons. App controls use the original SVG paths from the HTML sprite.

Geist, Geist Mono, and Rubik are bundled for offline use, with the weights specified in the HTML. Geist is the main typeface; Geist Mono is used for section labels; Rubik is assigned to the Arabic brand text with platform glyph fallback.

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

The HTML references are copied under `references/`; source files in Downloads are preserved. Regenerate launcher icons with `flutter test tool/generate_icons.dart`. Generate local visual QA pages with `python tool/reference_screens.py`. Language support was excluded from the approved tickets. Budget settings are available in History. Tap a savings card to edit the goal.
