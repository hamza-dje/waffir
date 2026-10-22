# Waffir 0.3.0 APK

- File: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
- Size: 18,199,317 bytes (17.36 MiB).
- SHA-256: `b47b0c53ca2a3ea7857ca236753b9cf8110595e63680595b365ff6fce9b209a7`.
- Display name: Waffir. Package: `com.example.wafir`.
- Version name: 0.3.0. Base build: 4. ARM64 APK version code: 2004.
- Android API 24 minimum; target API 36. ARM64 architecture only.
- Signing: existing Android debug key. APK v2 signature verified. This is a release-mode direct-install build; store distribution needs production signing.

## Build

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols/android
```

Only the ARM64 APK is retained in `flutter-apk/`. Other APKs and SHA-1 sidecars were removed after verification. Keep `build/symbols/android/*.symbols` with this release.

## Verification

- Analyzer: no issues.
- Twelve calculation and flow tests, plus one bundled-font visual capture test: passed.
- Checks cover the separate past/today/future calculations, the 200-dinar tomorrow-limit example, final-day and overspending states, migration without data loss, product snapshots, budget and expense corrections, date guards, deletion, fixed transfers, restart, SVG currency, outline-free inputs, and larger text on a small screen.
- ARM64 APK archive, ABI, package/version metadata, SVG/font/license bytes, and signature: verified.
- Android API 35 x86_64 companion release: installed over the previous app without clearing data. Native onboarding and a custom product logged 50 dinars, leaving 50 today, 101.72 future average, and 150 tomorrow limit. Correcting the expense to 150 produced -50 today and 98.28 future average.
- Native stop/save and carry-over created a 2850-dinar budget. A saved-history correction changed the old balance to 2950 while the transfer stayed 2850. Force-stop/restart restored the new budget.
- The final appearance build was reinstalled and cold-started. It restored 95 today, 98.28 future average, and 190 tomorrow limit. Native captures confirm the left-side faded currency mark, faded product icons, and one-row budget actions.
- On that final build, a new expense was logged, restored after restart, edited through the SVG-prefixed input, and deleted after confirmation. The carried budget returned to 2850 dinars, with 95 today and 190 tomorrow limit.

The ARM64 binary was not run on physical ARM64 hardware. Runtime checks used the companion x86_64 APK from the same source and build flags. JNI/Kotlin keep rules remain in `android/app/proguard-rules.pro` for release storage.

Source and records are committed. Build outputs and captures are excluded from Git. The app graph reflects the current code.
