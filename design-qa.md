# Waffir UX and visual check

Result: passed for the approved UX plan and later visual changes.

0.3.1 update: 14 tests pass, including case-insensitive history search with correct edit indices, custom expense icon persistence, and icon correction. Current bundled-font captures show the Home CTA, mint active-budget card, separate history totals, expense cards, visible detail input, icon picker, and one-row Budget amount/days and action buttons. Search uses the original SVG. These new layouts were checked in Flutter captures; the older native evidence below refers to 0.3.0.

Targets: `UX_PLAN.md`, the supplied HTML design tokens and SVG paths, and the user's screenshots and follow-up instructions. The approved three-tab UX replaces the original mockup flow.

## Evidence

- `build/ux/review-final.png`: Home, Budget, and Edit expense together, rendered with the bundled fonts at 390 × 844 logical pixels.
- `build/ux/onboarding-*.png`: dates, amount, and optional products.
- `build/ux/history*.png`, `expense.png`, and `edit-budget.png`: history and editing states.
- `build/ux/native/final-home.png` and `final-budget.png`: final release on Android, 540 × 1200 physical pixels at density 1.5 (360 × 800 logical pixels).
- Automated layout checks include a 360 × 696 screen with text enlarged to 150%.

## Verified surfaces

- Typography: bundled Geist and Geist Mono; Rubik remains available. The original average is visible, with Left today as the main figure.
- Currency: the exact supplied SVG is before each monetary amount, including the hero, keypad, product prices, history, and input values. Its height is 0.72 em to match visible digits; opacity is 65%. Accessible currency labels remain text.
- Icons: original SVG paths; usual-product icons use 55% opacity. Selection and navigation still have clear active states.
- Inputs: no visible outlines. Text and date labels are separate and above their controls.
- Buttons: Add product follows the medium primary style (44 px, 14 px radius, 14 px semibold text, 17 px icon). Edit budget and Stop and save budget are in one row. Main continue/save buttons retain the large 54 px style.
- Colors: original dark backgrounds, surfaces, mint, amber, and text colors. Negative figures and stop-spending warnings remain visible.
- Layout: Home, History, Budget; custom product grid; grouped editable history; scrollable forms; dates and saved budget records. The future average and tomorrow's maximum are separate figures.

## Platform differences

Android draws its own system bars. Flutter and Chromium text rasterization can differ. Live dates, amounts, and history replace mock data. There is no duplicated phone frame or system bar. Long content scrolls rather than being squeezed into a fixed screenshot.

No unresolved layout exceptions or analyzer findings remain. Native upgrade, corrections, carry-over, and restart checks passed. The final appearance build was cold-started and visually checked again; its SVG-prefixed input also passed native log, edit, delete, and restart checks.
