import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const mint = Color(0xFF34D399);
const background = Color(0xFF0F1115);
const surface = Color(0xFF171A21);
const surfaceHigh = Color(0xFF1F242D);
const primaryText = Color(0xFFF2F4F7);
const secondaryText = Color(0xFF8A93A2);
const tertiaryText = Color(0xFF5B6472);
const caution = Color(0xFFF5B84A);
const hairline = Color(0x0FFFFFFF);

// These files contain the original SVG paths from the supplied HTML sprite.
class SourceIcon extends StatelessWidget {
  const SourceIcon(this.name,
      {super.key, this.size = 20, this.color = primaryText});
  final String name;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/icons/$name.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
}

TextStyle type(double size,
        {Color color = primaryText,
        FontWeight weight = FontWeight.w400,
        double? spacing,
        double? height}) =>
    TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height);

Widget sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontFamily: 'GeistMono',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: tertiaryText)));

BoxDecoration panel({double radius = 20, Color color = surface}) =>
    BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius));

class CurrencySymbol extends StatelessWidget {
  const CurrencySymbol({super.key, this.size = 18, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: .65,
      child: SvgPicture.asset('assets/dzd.svg',
          width: size * 624 / 993,
          height: size,
          excludeFromSemantics: true,
          colorFilter: ColorFilter.mode(
              color ?? DefaultTextStyle.of(context).style.color ?? primaryText,
              BlendMode.srcIn)));
}

// Keep currency accessible as text while drawing the supplied vector mark.
class CurrencyText extends StatelessWidget {
  const CurrencyText(this.data,
      {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) {
    final matches = RegExp(r'([−-]?\d+(?:\.\d+)?)\s+(?:DZD|DA)\b')
        .allMatches(data)
        .toList();
    if (matches.isEmpty) {
      return Text(data,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow);
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      spans.add(TextSpan(text: data.substring(cursor, match.start)));
      final fontSize =
          style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
      spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
              padding: EdgeInsets.only(right: fontSize * .16),
              child:
                  CurrencySymbol(size: fontSize * .72, color: style?.color))));
      spans.add(TextSpan(text: match.group(1)));
      cursor = match.end;
    }
    spans.add(TextSpan(text: data.substring(cursor)));
    return Text.rich(TextSpan(children: spans),
        semanticsLabel: data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField(
      {super.key,
      required this.label,
      required this.controller,
      this.currency = false,
      this.maxLength,
      this.validator,
      this.enabled = true});
  final String label;
  final TextEditingController controller;
  final bool currency;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CurrencyText(label,
            style: type(13, color: secondaryText, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Semantics(
            label: label,
            child: TextFormField(
                key: ValueKey('input-$label'),
                controller: controller,
                enabled: enabled,
                maxLength: maxLength,
                keyboardType:
                    currency ? TextInputType.number : TextInputType.text,
                validator: validator,
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    prefix: currency
                        ? const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: CurrencySymbol(size: 12))
                        : null))),
      ]);
}
