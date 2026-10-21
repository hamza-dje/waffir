# Waffir APK

## Smaller release files

Built with Flutter's size-reduction flags:

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols/android
flutter build appbundle --release --split-debug-info=build/symbols/android
```

| File | Size | SHA-256 |
| --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 17.36 MiB | `5761707fc543c3f00ca5097fdb4cf0eb07faf79fb4048c8ec83c34d1a4be00f3` |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` | 14.70 MiB | `2df9d9ca65a8eeec4743fee6787c0faf0af8bd1473b9bc2e2fd3d73b4271425f` |
| `build/app/outputs/flutter-apk/app-x86_64-release.apk` | 18.83 MiB | `8d64d85d0f0762706df9c1cb7971a918e394c8278b88d56c84ee806138d28b21` |
| `build/app/outputs/bundle/release/app-release.aab` | 47.15 MiB | `3d0eaf01aef3928143a9eb202cadbdfc197b04c18b83e1699cdd3cf93c70333a` |

The ARM64 APK is 65.93% smaller than the universal APK. Each split APK contains one processor architecture. The AAB contains all architectures; a store generates device-specific downloads from it. It is not installed directly.

All split APK signatures and ZIP integrity checks passed. Their Flutter assets match the previously verified universal APK byte for byte. The AAB archive and JAR signature checks passed. Signing still uses the debug key. No app code or design assets changed. These size builds were not launched on a device.

Keep `build/symbols/android/*.symbols` with the release for crash symbolization. Icon tree shaking remains enabled by default. The existing universal APK is retained below for devices of unknown architecture.

## Original universal APK

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
