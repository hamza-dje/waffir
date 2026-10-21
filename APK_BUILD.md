# Waffir APK

- Version: 0.2.1 (3).
- File: `build/app/outputs/flutter-apk/app-release.apk`.
- Size: 53,418,387 bytes (50.9 MiB).
- SHA-256: `093878cdb27a3bfc93d7e5418ba9fc75ffcf793139794e9fee69c65e355a99a5`.
- Package: `com.example.wafir`.
- Requires Android 7.0 (API 24) or later. Targets API 36.
- Architectures: arm64-v8a, armeabi-v7a, x86_64.
- Build: `flutter build apk --release`.
- Signing: Android debug key; APK v2 signature verified. This is a release-mode build for direct installation, not a store-signed release.
- Display name: Waffir. The package ID is retained for data compatibility.
- Passed: analyzer, seven flow tests, one six-screen capture test, release build, APK ZIP integrity, all three ABIs, bundled fonts, SVG assets, and signature verification.
- Android API 35: upgrade and real storage startup passed. The native keypad saved 120 DZD; force-stop/restart restored the expense and 8830 DZD left in the test budget.
- All four approved tickets are complete. The language ticket was removed. Budgets, period renewal, retained history, expenses, fixed costs, savings goals, reference price checks, and local storage are implemented.

The JNI/Kotlin keep rules in `android/app/proguard-rules.pro` prevent release shrinking from removing classes used by the preferences plugin. See `design-qa.md` for the visual comparison and native-platform differences.

Build output is excluded from Git. This record and the graphify app map are committed.
