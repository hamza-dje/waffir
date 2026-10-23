import 'package:flutter/material.dart';
import '../design/design.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filled(
      tooltip: 'Back',
      onPressed: onPressed,
      style: IconButton.styleFrom(
          backgroundColor: cancelSurface,
          foregroundColor: primaryText,
          minimumSize: const Size(compactActionHeight, compactActionHeight),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      icon: const RotatedBox(
          quarterTurns: 2, child: SourceIcon('chevron-right')));
}

AppBar editorBar(BuildContext context, String title) => AppBar(
    leading: Padding(
        padding: const EdgeInsets.all(6),
        child: AppBackButton(onPressed: () => Navigator.pop(context))),
    title: CurrencyText(title,
        style: type(20, role: TextRole.display, weight: FontWeight.w600)));

Future<bool> confirmAction(BuildContext context, String title, String message,
        String action) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: surface,
              title: CurrencyText(title),
              content: CurrencyText(message),
              actions: [
                DialogActions(
                    onCancel: () => Navigator.pop(context, false),
                    onConfirm: () => Navigator.pop(context, true),
                    confirmLabel: action)
              ],
            )) ??
    false;
