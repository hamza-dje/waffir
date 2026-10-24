<p align="center">
  <img src="docs/app-icon.svg" width="88" height="88" alt="Waffir app icon with rounded corners">
</p>
<p align="center">
  <img src="docs/app-name.svg" width="400" alt="Waffir - وفّر">
</p>

<br>

**A coffee today. Enough for the bus tomorrow.**

A small money journal for Algerian students. Give your allowance a plan, log the little things, track money lent or borrowed, and see what is left before the next purchase.

<sub>ALGERIAN DINARS / WORKS OFFLINE / NO ACCOUNT</sub>

<p align="center">
  <a href="#a-day-with-waffir">A day with Waffir</a> ·
  <a href="#money-between-friends">Loans</a> ·
  <a href="#before-your-first-lecture">First budget</a> ·
  <a href="#the-maths-behind-the-day">The maths</a> ·
  <a href="#run-it-yourself">Build it</a>
</p>

---

## A day with Waffir

<table>
  <tr>
    <td width="42%" align="center">
      <img src="docs/screenshots/home.png" width="260" alt="Home shows money left today, daily averages, savings, and a loan summary">
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

## Money between friends

**Books for a friend. Bus money borrowed until next week. Keep both in view.**

Loans has two clear directions: **Owed to me** and **I owe**. Save the person's name, amount, loan date, and an optional due date and note. The popup shows the effect on your budget before you save.

| Keep track | Settle up |
| --- | --- |
| Filter by All, Owed to me, I owe, or Paid. | Record part of a repayment or the full amount. |
| Search by person or note. Overdue loans appear first. | See the unpaid balance and payment history. |
| Edit details if you made a mistake. | Correct payments or delete them after confirmation. |

<p align="center">
  <img src="docs/screenshots/loans.png" width="265" alt="Loans overview with totals, search, filters, and due status">
  <img src="docs/screenshots/loan-details.png" width="265" alt="Loan details with remaining amount, repayment action, dates, note, and reminders">
</p>

### Cash in hand, money expected back

Loan transfers change cash. They do **not** count as expenses or savings.

- **You lend:** cash falls at once. If repayment is due within the budget period, the planned daily limit can include that expected money until the due date ends. With no due date, a due date after the budget ends, or an overdue balance, the unpaid amount reduces the limit.
- **You borrow:** cash rises. Money owed within the budget period, or without a due date, is reserved for repayment. Borrowing due after the period can increase the spending limit, while the debt remains visible.
- **You record a repayment:** cash and limits update. Payments cannot exceed the amount still owed. A transfer above available cash needs confirmation.

Home separates cash, expected repayments, and repayment reserves. If Left today depends on money that has not returned, it shows a warning. Tomorrow's figures also account for loans.

Loans stay open when a budget closes. Each transfer has its own budget link, or **Outside a budget**. A repayment in a later budget affects that budget; old loans do not add money to a new budget automatically. Existing links and carry-over amounts stay fixed after budget corrections.

### A reminder at noon

Dated loans can send a phone notification at **12:00 PM local time** on the due day and once the next day if money is still owed. The alert shows the unpaid amount and direction, with no person's name. Tap it to open the loan.

Reminders are on by default for dated loans and can be switched off per loan. Waffir asks for notification permission when needed. A late entry can trigger one immediate reminder. Partial payments update the amount; full repayment or deletion cancels the alerts. Android may delay scheduled alerts to save battery.

<details>
<summary><b>See the repayment popup</b></summary>

<p align="center">
  <img src="docs/screenshots/repayment.png" width="265" alt="Record a repayment with amount, date, time, budget link, and cash preview">
</p>

</details>

## Before your first lecture

**Choose a period. Add your money. Save your usual purchases.**

Use a **7, 15, 21, or 28-day** shortcut, or choose dates that match your next payment. The duration appears directly below the date inputs. Both the start and end dates count. Enter the full budget in whole dinars. Products are optional and can be added later.

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

With no loan transfers, suppose you set **3,000 DA for 30 days**. Your original daily average is **100 DA**. If you spend **50 DA on day one**:

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

Past savings or overspending affect the next day's allowance. Today's purchases reduce Left today, but do not change today's fixed limit. Loan entries, repayments, due-date changes, and overdue balances can change the planned limit. Negative figures stay visible. At zero or below, Home shows **Stop for today**. On the last day, future figures show **No days remaining**.

<details>
<summary><b>Small details that matter</b></summary>

Waffir uses a dark theme, mint primary actions, gray Edit and secondary buttons, and amber warnings. Delete actions use muted red with red text; confirmation buttons remain red. **Geist** stays on headings and key amounts. **Red Hat Display** is used for body text, labels, and controls. Geist Mono and Rubik remain bundled, with all font licenses included.

The supplied [dinar symbol](assets/dzd.svg) appears to the left of amounts with reduced opacity. Product icons are also muted. Fields have separate labels, placeholders, and no visible outlines. Standard actions share a 54 px minimum height, 16 px text, and semibold weight. Edit and Stop and Save use the compact button size. Compact actions use a 44 px minimum height. Back controls share a dark rounded surface. The inset tab bar is darker than the section cards; content is visible through its rounded top corners and hidden below it. Related controls use tighter spacing than separate sections.

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

- Budgets, products, expense logs, loans, and repayments are stored locally using SharedPreferences. There is no cloud sync or export feature.
- Clearing app data or uninstalling the app can remove your records.
- Saved budgets remain editable, but cannot receive new expenses.
- Money carried into a new budget stays fixed if you later correct the old budget.
- Budget date edits cannot exclude existing expenses. Correct those expenses first.
- Legacy budget data is migrated while retaining the original legacy storage key for recovery.

## Run it yourself

<details>
<summary><b>Flutter setup, checks, APK build, and source map</b></summary>

Current release: **0.4.0, build 11**.

This is a Flutter project. Install Flutter and the Android SDK, then run:

```sh
flutter pub get
flutter run
```

Check the code and user flows:

```sh
flutter analyze
flutter test
flutter test test/presentation/design_capture.dart
```

Build smaller APKs for each processor type:

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols/android
```

The generated ARM64 output is `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Shared APKs use `waffir-release-<version>+<build>.apk`, such as `waffir-release-0.4.0+11.apk`. Build outputs are not stored in Git. Keep the debug symbol files with the release. The current Android build uses the debug signing key; set a production key before store distribution.

The code uses a layer-first structure:

```text
lib/
  main.dart                 # Supplies storage and phone notifications
  domain/
    models/                 # Budgets, expenses, loans, and daily figures
    rules/                  # Expense rules and loan reminder planning
    repositories/           # Typed storage contract
  data/
    serialization/          # JSON schema and legacy migration
    storage/                # SharedPreferences implementation
    notifications/          # Phone permissions, scheduling, and loan links
  presentation/
    app.dart                # App theme and root navigation
    controllers/            # Budget lifecycle and save state
    screens/                # Home, History, Loans, Budget, and editors
    widgets/                # Shared forms, cards, lists, popups, and navigation
    design/                 # Colors, spacing, button styles, and formatting
```

The domain has no Flutter or storage-plugin dependency. Presentation and data depend on the domain. `main.dart` connects them. Tests follow the same layers; `test/architecture_test.dart` checks the dependency direction and prevents shared widgets from importing screens.

</details>

---

<p align="center">
  <strong>A small habit between classes. A clearer view of your money.</strong><br>
  Waffir - made for student life in Algeria 🇩🇿
</p>

Found a bug or have an idea? <a href="https://github.com/hamza-dje/waffir/issues">Open an issue</a> with the screen, steps, and expected result. Hide personal details in screenshots.

## Dinar symbol credit

The dinar symbol used in Waffir's app icon and currency displays comes from [رمز الدينار الجزائري](https://www.behance.net/gallery/220609691/_) by [Salah Eddine Mrezegue](https://www.behance.net/Mrazag), credited in the project as Mrezag Salaheddine. The original symbol design belongs to its creator. The project states that all rights are reserved.
