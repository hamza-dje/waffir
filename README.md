# Wafir / وفّر

Flutter implementation started from the supplied product and button-system HTML references.

Implemented: weekly or 30-day budget setup, daily allowance calculated from remaining money and days, quick expenses, validated custom expenses, history, and local persistence. The supplied DZD SVG is used as the in-app brand mark, recolored through an SVG color filter; the original asset is preserved.

Budget amounts are whole DZD. Setup asks for money available after fixed costs and savings. No demo transactions or live prices are inserted. An expired period currently retains its history and uses one remaining day until period rollover is implemented.

## Run

Use Flutter on PATH, or `C:\Users\hamza\develop\flutter\bin\flutter.bat` on this machine:

```
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

The HTML references are copied under `references/`; source files in Downloads are preserved. Android, iOS, and web launcher icons use the supplied SVG. Regenerate with `flutter test tool/generate_icons.dart`. Custom periods, fixed costs, savings goals, price advice, and period rollover remain future slices.
