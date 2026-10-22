<p align="center">
  <img src="docs/app-icon.svg" width="88" height="88" alt="Waffir app icon with rounded corners">
</p>
<p align="center">
  <img src="docs/app-name.svg" width="400" alt="Waffir - وفّر">
</p>

<br>

**A coffee today. Enough for the bus tomorrow.**

A small money journal for Algerian students. Give your allowance a plan, log the little things, and see what is left before the next purchase.

<sub>ALGERIAN DINARS / WORKS OFFLINE / NO ACCOUNT</sub>

<p align="center">
  <a href="#a-day-with-waffir">A day with Waffir</a> ·
  <a href="#before-your-first-lecture">First budget</a> ·
  <a href="#the-maths-behind-the-day">The maths</a> ·
  <a href="#run-it-yourself">Build it</a>
</p>

---

## A day with Waffir

<table>
  <tr>
    <td width="42%" align="center">
      <img src="docs/screenshots/home.png" width="260" alt="Home shows 51.72 DA left today, daily averages, savings, and usual products">
    </td>
    <td>
      <h3>One number before you spend.</h3>
      <p>Open Home. <b>Left today</b> tells you what remains of today's allowance.</p>
      <p>Below it: what you spent, what you saved, and what tomorrow could look like.</p>
      <p>Your usual coffee? One tap.<br>A bus ride? One tap.<br>Something different? <b>Add expense.</b></p>
      <hr>
      <p><b>Yesterday</b> helps set today's limit.<br><b>Today</b> has its own spending room.<br><b>Tomorrow</b> updates as you spend.</p>
      <p><sub>Screen shown with sample data.</sub></p>
    </td>
  </tr>
</table>

### Small purchases, written down

You remember the big payment. Coffee, water, and snacks are easier to forget. Give each purchase a name and icon, then get on with your day.

| Between classes | At the end of the day |
| --- | --- |
| Tap a saved product to log its usual price. | Open History and search by name. |
| For a new expense: amount → Continue → name, icon, time → Log it. | Correct a name, amount, icon, date, or time. Delete a mistake after confirmation. |
| Choose your own prices and products. | Keep the record, even after you close the budget. |

<p align="center">
  <img src="docs/screenshots/expense-details.png" width="265" alt="Name an expense, choose an icon and time, then tap Log it">
  <img src="docs/screenshots/history-details.png" width="265" alt="Search expense cards and check budget totals in History">
</p>
<p align="center"><sub>Write it down. Find it later. Fix it if needed.</sub></p>

## Before your first lecture

**Choose a period. Add your money. Save your usual purchases.**

Use a week, a month, or dates that match your next payment. Both the start and end dates count. Enter the full budget in whole dinars. Products are optional and can be added later.

<details>
<summary><b>See the three setup screens</b></summary>

| Your dates | Your amount | Your everyday purchases |
| :---: | :---: | :---: |
| <img src="docs/screenshots/onboarding-dates.png" width="235" alt="Choose your budget start and end dates"> | <img src="docs/screenshots/onboarding-amount.png" width="235" alt="Enter the full amount in dinars"> | <img src="docs/screenshots/onboarding-products.png" width="235" alt="Add usual products or skip this step"> |

</details>

## When plans change

<table>
  <tr>
    <td>
      <h3>Your budget can change with you.</h3>
      <p>Entered the wrong amount? <b>Edit</b> it.<br>A usual price changed? Update the product.<br>Starting a new period? <b>Stop and Save.</b></p>
      <p>Keep the old budget in History. Start the next one with the positive balance left, or enter a new amount.</p>
      <p>Past logs keep their prices when a product changes. Money already carried forward stays fixed when you correct an older budget.</p>
    </td>
    <td width="42%" align="center">
      <img src="docs/screenshots/budget.png" width="260" alt="Budget settings with Edit, Stop and Save, and usual products">
    </td>
  </tr>
</table>

## The maths behind the day

Suppose you set **3,000 DA for 30 days**. Your original daily average is **100 DA**. If you spend **50 DA on day one**:

| Figure | Result | Meaning |
| --- | --- | --- |
| Original daily average | 100 DA | Full budget ÷ all budget days. |
| Today's limit | 100 DA | Today's allowance, fixed before today's purchases. |
| Spent today | 50 DA | Purchases logged today. |
| Left today | 50 DA | Today's limit minus today's spending. |
| Daily average from tomorrow | 101.72 DA | 2,950 DA spread over the next 29 days. |
| Tomorrow's limit | 150 DA | Maximum for tomorrow that leaves the original average for each later day. |

**Saved so far** compares the original allowance for completed days with what you spent on those days. Today is excluded until it ends. Tomorrow's limit includes today's result:

```text
Tomorrow's limit = original daily average + saved so far
                  + original daily average − spent today
```

Past savings or overspending affect the next day's allowance. Today's purchases reduce Left today, but do not change today's fixed limit. Negative figures stay visible. At zero or below, Home shows **Stop for today**. On the last day, future figures show **No days remaining**.

<details>
<summary><b>Small details that matter</b></summary>

Waffir uses a dark theme, mint actions, and amber warnings. It bundles **Geist**, **Geist Mono**, and **Rubik**, with their font licenses.

The supplied [dinar symbol](assets/dzd.svg) appears to the left of amounts with reduced opacity. Product icons are also muted. Fields have separate labels and no visible outlines.

| Icon | Example use |
| --- | --- |
| <img src="assets/icons/coffee.svg" width="24" alt="Coffee icon"> | Coffee or tea |
| <img src="assets/icons/sandwich.svg" width="24" alt="Sandwich icon"> | A snack |
| <img src="assets/icons/bus.svg" width="24" alt="Bus icon"> | Transport |
| <img src="assets/icons/droplet.svg" width="24" alt="Water icon"> | Water |
| <img src="assets/icons/utensils.svg" width="24" alt="Meal icon"> | Lunch or dinner |
| <img src="assets/icons/banknote.svg" width="24" alt="Money icon"> | Other spending |

These are examples. You choose the label and icon. Changing a usual product's price affects future taps; past logs keep their recorded amounts.

</details>

## Your records, on your device

- Budgets, products, and logs are stored locally using SharedPreferences. There is no cloud sync or export feature.
- Clearing app data or uninstalling the app can remove your records.
- Saved budgets remain editable, but cannot receive new expenses.
- Money carried into a new budget stays fixed if you later correct the old budget.
- Budget date edits cannot exclude existing expenses. Correct those expenses first.
- Existing budget data is migrated while retaining the old storage value for recovery.

## Run it yourself

<details>
<summary><b>Flutter setup, checks, APK build, and source map</b></summary>

This is a Flutter project. Install Flutter and the Android SDK, then run:

```sh
flutter pub get
flutter run
```

Check the code and user flows:

```sh
flutter analyze
flutter test
flutter test test/design_capture.dart
```

Build smaller APKs for each processor type:

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols/android
```

The ARM64 output is `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Build outputs are not stored in Git. Keep the debug symbol files with the release. The current Android build uses the debug signing key; set a production key before store distribution.

| Source | Purpose |
| --- | --- |
| `lib/budget_data.dart` | Budget records, storage format, and daily calculations |
| `lib/main.dart` | Home, History, Budget, and app state |
| `lib/onboarding.dart` | Budget setup and amount keypad |
| `lib/expense_sheet.dart` | Two-step custom expense flow |
| `lib/editors.dart` | Budget, expense, and product editing |
| `lib/design.dart` | Shared colors, text, currency, and input widgets |
| `assets/` | SVG icons, currency mark, and fonts |
| `test/` | Calculation, user-flow, and screen-capture checks |

</details>

---

<p align="center">
  <strong>A small habit between classes. A clearer view of your money.</strong><br>
  Waffir - made for student life in Algeria 🇩🇿
</p>

Found a bug or have an idea? <a href="https://github.com/hamza-dje/waffir/issues">Open an issue</a> with the screen, steps, and expected result. Hide personal details in screenshots.

## Dinar symbol credit

The dinar symbol used in Waffir's app icon and currency displays comes from [رمز الدينار الجزائري](https://www.behance.net/gallery/220609691/_) by [Salah Eddine Mrezegue](https://www.behance.net/Mrazag), credited in the project as Mrezag Salaheddine. The original symbol design belongs to its creator. The project states that all rights are reserved.
