import 'package:flutter/material.dart';
import '../design/design.dart';

AppBar editorBar(BuildContext context, String title) => AppBar(
    leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
        icon: const SourceIcon('arrow-left')),
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
