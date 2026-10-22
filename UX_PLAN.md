# Approved Waffir flow

- Keep the existing colors, bundled fonts, and source SVG icons.
- Use the supplied DZD SVG for currency labels. Remove visible outlines from controls, cards, and inputs.
- Put the currency mark beside every amount at the visible height of the digits. Input labels are separate and above their fields. Budget edit and stop actions share one row. Add product uses the supplied medium primary button style.
- Currency marks are on the left at 65% opacity. Usual-product icons are at 55% opacity. Amounts remain fully visible.
- Onboarding: budget dates, full amount, then optional usual products with prices and icons. No preset products.
- Tabs: Home, History, Budget. Remove price check.
- Home: Left today is the large figure. Keep the initial daily average visible. Also show today's limit and spending, calculated savings, and the projected daily average from tomorrow.
- With B funds, N inclusive calendar days, C completed days, P spending before today, and T spending today: initial average = B/N; today's fixed limit = (B-P)/(N-C); Left today = limit-T; savings = (B/N)*C-P; upcoming average = (B-P-T)/(N-C-1).
- Tomorrow's safe limit = original average + savings + (original average - today's spending). It includes today's result and leaves the original daily average for every day after tomorrow. Hide this limit when no future day remains.
- Purchases do not change today's limit. Corrections to past spending or budget dates recalculate it. Negative balances and savings remain visible. At zero Left today, show Stop for today. There is no upcoming average on the last day or after expiry. Block new logging outside the active dates.
- Usual products: create, edit, delete; select an existing icon or use a generic icon. One tap logs the usual price. Product edits never change old expenses.
- Expenses: edit name, amount, date, or delete after confirmation, in active and saved budgets. Block dates outside the budget or in the future.
- Budget: edit amount, start, and end dates. Block date changes that exclude existing expenses. Manage usual products here.
- Stop and save at any time. Saved budgets accept corrections but no new spending. Offer a new budget from the remaining positive balance or a new amount, with new dates. Later corrections to the saved budget never change a completed transfer.
- Keep existing funds, dates, and expenses. Remove fixed-cost deductions and manual savings reserves. Preserve legacy data for recovery. Historical expenses whose original budget is unknown stay clearly identified.
- Test the calculations, persistence, migration, corrections, rollover, and UI. Build the smaller ARM64 APK with split debug information. Keep only that APK in flutter-apk/. Commit each logical change and refresh the app graph.
