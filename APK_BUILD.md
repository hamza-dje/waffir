# Waffir 0.3.1 APK

- File: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
- Size: 18,461,625 bytes (17.61 MiB).
- SHA-256: `6a4b7e68e115934dcc553798762d12b3540535fec5736dc32140362b64b9c910`.
- Display name: Waffir. Package: `com.example.wafir`.
- Version: 0.3.1+5. ARM64 version code: 2005.
- Android API 24 minimum; target API 36. ARM64 only.
- Release mode, existing debug signing key. APK v2 signature verified.

## Build

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols/android
```

Only the ARM64 APK is retained in `flutter-apk/`. Keep `build/symbols/android/*.symbols` with the release.

## Checks

- Analyzer: no issues.
- 14 calculation, flow, and bundled-font capture tests passed.
- Checks cover persistence, migration, budget corrections, fixed transfers, icon creation/editing, hidden empty products, name search with correct edit indices, and small-screen layouts with enlarged text.
- Archive integrity, ARM64 ABI, SVG/font/license asset bytes, package/version, and signature verified.
- New layouts were inspected in Flutter captures. This version was not installed on Android hardware or an emulator. Earlier native storage checks apply to 0.3.0; the release storage keep rules remain in place.

Source changes and release records are committed. Build outputs and captures are excluded from Git.
