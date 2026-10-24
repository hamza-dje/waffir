import 'package:flutter/material.dart';
import '../design/design.dart';
import 'editor_actions.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.color = surface});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child));
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
