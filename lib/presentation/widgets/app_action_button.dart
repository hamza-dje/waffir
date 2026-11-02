import 'package:flutter/material.dart';
import 'press_feedback.dart';

/// Shared action button. Native focus, disabled states and styles are retained.
class AppActionButton extends StatelessWidget {
  const AppActionButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.style,
      this.animate = true})
      : icon = null;
  const AppActionButton.icon(
      {super.key,
      required this.onPressed,
      required Widget label,
      required this.icon,
      this.style,
      this.animate = true})
      : child = label;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final bool animate;

  @override
  Widget build(BuildContext context) => PressFeedback(
      enabled: animate && onPressed != null,
      child: icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: child)
          : FilledButton.icon(
              onPressed: onPressed, style: style, icon: icon!, label: child));
}
