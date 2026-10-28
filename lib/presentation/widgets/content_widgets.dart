import 'package:flutter/material.dart';
import '../design/design.dart';
import 'editor_actions.dart';

class AmountStatCard extends StatelessWidget {
  const AmountStatCard(
      {super.key,
      required this.label,
      required this.value,
      this.color = primaryText,
      this.backgroundColor = surface,
      this.valueKey,
      this.labelHeight});
  final String label, value;
  final Color color, backgroundColor;
  final Key? valueKey;
  final double? labelHeight;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: panel(radius: 16, color: backgroundColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            height: labelHeight,
            child: CurrencyText(label, style: type(11, color: secondaryText))),
        const SizedBox(height: 6),
        CurrencyText(value,
            key: valueKey,
            style: type(21,
                role: TextRole.display, color: color, weight: FontWeight.w600)),
      ]));
}

class AppActionIcon extends StatelessWidget {
  const AppActionIcon(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onPressed,
      this.destructive = false});
  final String icon, tooltip;
  final VoidCallback? onPressed;
  final bool destructive;
  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: compactActionHeight,
      child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: (destructive ? deleteAction(compact: true) : backAction())
              .copyWith(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          icon: SourceIcon(icon,
              size: 18, color: destructive ? danger : primaryText)));
}

class AppFilters extends StatelessWidget {
  const AppFilters(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: spaceTight, runSpacing: spaceTight, children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(controlRadius)),
              label: Text(labels[i]),
              selected: selected == i,
              onSelected: (_) => onChanged(i),
              showCheckmark: false,
              side: BorderSide.none,
              selectedColor: const Color(0x2634D399),
              backgroundColor: surface,
              labelStyle: buttonType(12)
                  .copyWith(color: selected == i ? mint : secondaryText))
      ]);
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard(
      {super.key,
      required this.child,
      this.color = surface,
      this.padding = const EdgeInsets.all(16),
      this.radius = sectionRadius});
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child));
}

class SearchInput extends StatelessWidget {
  const SearchInput(
      {super.key,
      required this.hint,
      required this.onChanged,
      this.hintColor = tertiaryText});
  final String hint;
  final ValueChanged<String> onChanged;
  final Color hintColor;
  @override
  Widget build(BuildContext context) => TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: type(14, color: hintColor),
          prefixIcon: const Padding(
              padding: EdgeInsets.all(14),
              child: SourceIcon('search', color: secondaryText))));
}

class DetailField extends StatelessWidget {
  const DetailField({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, style: type(13, color: secondaryText)),
        const SizedBox(height: 6),
        CurrencyText(value,
            style: type(14, weight: FontWeight.w500, height: 1.5)),
      ]));
}

class FormSheet extends StatelessWidget {
  const FormSheet(
      {super.key, required this.title, required this.children, this.onBack});
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            decoration: panel(radius: 2, color: tertiaryText))),
                    const SizedBox(height: 20),
                    PageHeading(
                        title: title,
                        leading: onBack == null
                            ? null
                            : AppBackButton(onPressed: onBack)),
                    const SizedBox(height: 20),
                    ...children
                  ]))));
}
