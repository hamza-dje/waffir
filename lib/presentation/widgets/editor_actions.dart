import 'package:flutter/material.dart';
import '../design/design.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filled(
      tooltip: 'Back',
      onPressed: onPressed,
      style: backAction().copyWith(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const WidgetStatePropertyAll(
              Size(compactActionHeight, compactActionHeight)),
          fixedSize: const WidgetStatePropertyAll(
              Size(compactActionHeight, compactActionHeight)),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(spaceRelated))),
      icon: const RotatedBox(
          quarterTurns: 2, child: SourceIcon('chevron-right', size: 16)));
}

class PageHeading extends StatelessWidget {
  const PageHeading(
      {super.key,
      required this.title,
      this.leading,
      this.style,
      this.backAbove = false});
  final String title;
  final Widget? leading;
  final TextStyle? style;
  final bool backAbove;
  @override
  Widget build(BuildContext context) {
    final heading = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: style ??
                type(22, role: TextRole.display, weight: FontWeight.w600)));
    if (backAbove && leading != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        leading!,
        const SizedBox(height: spaceRelated),
        heading,
      ]);
    }
    return Row(children: [
      if (leading != null) ...[leading!, const SizedBox(width: spaceRelated)],
      Expanded(child: heading),
    ]);
  }
}

AppBar editorBar(BuildContext context, String title) => AppBar(
    leadingWidth: pageInset + compactActionHeight + spaceRelated,
    titleSpacing: 0,
    leading: Padding(
        padding: const EdgeInsets.fromLTRB(pageInset, 6, spaceRelated, 6),
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
