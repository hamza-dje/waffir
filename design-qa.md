# Waffir design check

Result: passed with native-platform and functional-content differences listed below.

Reference: both supplied HTML files. The product HTML supplies the six screens and SVG paths. The button HTML supplies the 14 px button radius. The supplied DZD SVG supplies the launcher mark.

Evidence: `build/design/comparison.png` places each source capture beside its Flutter capture. Both content regions are 360 × 696 px at scale 1. The source catalog originally uses 316 × 696 px screens; the QA page adjusts only the frame width to the test viewport. Native Android screenshots use 540 × 1200 physical pixels at density 1.5, or 360 × 800 logical pixels.

## Fixed during comparison

- Replaced Material icons with the unchanged SVG sprite paths. Preserved the HTML backspace character as a vector glyph.
- Replaced the outlined quick-log buttons and Material navigation indicator with the source grid and plain icon tabs.
- Corrected the setup amount: centered number, unit below, keypad below the flexible amount area.
- Corrected card spacing, section labels, savings typography, currency labels, caution badge, and highlighted allowance text.
- Removed the extra selected-card check and extra History summary line.
- Repeated the six-screen capture after these changes. No layout exceptions occurred at the smaller viewport.

## Fidelity surfaces

- Fonts: local Geist 400–700, Geist Mono 400–500, and Rubik 400–600. Hero and amount figures use Geist; section labels use Geist Mono. Platform text rasterization can differ from Chromium.
- Layout: source padding, card radii, three-column grids, keypad, sheet, grouped history, settings rows, and tab arrangement are applied. Content scrolls when needed. Native safe areas replace the mock phone frame.
- Colors: source background, surface, text, mint, amber, borders, and progress colors are used.
- Images and icons: no raster substitutes. SVG paths remain scalable. The backspace vector avoids a missing-glyph box.
- Copy: source headings and control labels are used. Dates, amounts, reserves, progress, history, and price impact come from app state.

## Expected differences

- Android draws its own status and navigation bars. The app does not draw a second phone frame or status bar.
- The mock's food-equivalent sentence is replaced by remaining money and days. Reference prices remain marked as examples, not live market data.
- Optional expense notes, quotes, and source information remain available. Language stays English because the language ticket was removed.
- The source's `.today` selector also enlarges the active period dot. The app uses the intended 6 px dot rather than reproducing that CSS collision.
- The mock contains fixed logged-chip and savings states. The live app shows saved data and permits repeated expenses.

Checks: seven flow tests, one six-screen capture test, analyzer, native APK upgrade and restart, native keypad save and restart, APK integrity, all three ABIs, font assets, and signature verification.

Regenerate captures with `flutter test test/design_capture.dart`. Generate the source pages with `python tool/reference_screens.py` and serve the workspace locally.
