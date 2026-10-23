import 'package:flutter/material.dart';
import '../domain/repositories/budget_storage.dart';
import 'design/design.dart';
import 'screens/budget_screen.dart';
import 'screens/loans_screen.dart';

class WafirApp extends StatelessWidget {
  const WafirApp(
      {super.key, required this.storage, this.syncReminders, this.loanOpen});
  final BudgetStorage storage;
  final ReminderSync? syncReminders;
  final ValueNotifier<String?>? loanOpen;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Waffir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'RedHatDisplay',
          fontFamilyFallback: const ['Rubik'],
          brightness: Brightness.dark,
          textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: primaryText,
              displayColor: primaryText,
              fontFamily: 'RedHatDisplay'),
          appBarTheme: const AppBarTheme(
              backgroundColor: background,
              surfaceTintColor: Colors.transparent),
          scaffoldBackgroundColor: background,
          colorScheme: const ColorScheme.dark(primary: mint, surface: surface),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              textStyle: buttonType(16),
              minimumSize: const Size(48, 54),
              foregroundColor: const Color(0xFF06251A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: surface,
            titleTextStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: primaryText),
            insetPadding: overlayInsets,
            constraints: BoxConstraints(minWidth: 560, maxWidth: 560),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
              constraints: BoxConstraints(maxWidth: 680)),
          datePickerTheme: DatePickerThemeData(
              cancelButtonStyle: compactAction(cancel: true),
              confirmButtonStyle: compactAction()),
          timePickerTheme: TimePickerThemeData(
              cancelButtonStyle: compactAction(cancel: true),
              confirmButtonStyle: compactAction()),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            hintStyle: type(14, color: secondaryText),
            fillColor: surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  backgroundColor: surface,
                  foregroundColor: primaryText,
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  textStyle: buttonType(14, spacing: -.14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)))),
          textButtonTheme: TextButtonThemeData(style: secondaryAction()),
        ),
        home: BudgetScreen(
            storage: storage, syncReminders: syncReminders, loanOpen: loanOpen),
      );
}
