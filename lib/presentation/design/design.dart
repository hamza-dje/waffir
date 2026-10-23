import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const mint = Color(0xFF34D399);
const background = Color(0xFF0F1115);
const surface = Color(0xFF171A21);
const surfaceHigh = Color(0xFF1F242D);
const primaryText = Color(0xFFF2F4F7);
const secondaryText = Color(0xFF8A93A2);
const tertiaryText = Color(0xFF5B6472);
const danger = Color(0xFFEF6464);
const actionHeight = 54.0;
const compactActionHeight = 44.0;
const listItemGap = 12.0;
const spaceTight = 8.0;
const spaceRelated = 12.0;
const spaceSection = 24.0;
const pageInset = 20.0;
const controlRadius = 14.0;
const sectionRadius = 20.0;
const navigationClearance = 112.0;
const navigationSurface = Color(0xFF12151B);
TextStyle buttonType(double size, {double? spacing}) => TextStyle(
    fontFamily: 'RedHatDisplay',
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: spacing);

ButtonStyle deleteAction() => FilledButton.styleFrom(
    backgroundColor: const Color(0x1FEF6464),
    foregroundColor: danger,
    textStyle: buttonType(16));

ButtonStyle editAction() => FilledButton.styleFrom(
    backgroundColor: cancelSurface,
    foregroundColor: primaryText,
    textStyle: buttonType(16),
    minimumSize: const Size(48, actionHeight));

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

enum TextRole { body, display }

TextStyle type(double size,
        {Color color = primaryText,
        TextRole role = TextRole.body,
        FontWeight weight = FontWeight.w400,
        double? spacing,
        double? height}) =>
    TextStyle(
        fontFamily: role == TextRole.display ? 'Geist' : 'RedHatDisplay',
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height);

Widget sectionLabel(String text, {double horizontalPadding = 4}) => Padding(
    padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontFamily: 'RedHatDisplay',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: tertiaryText)));

BoxDecoration panel({double radius = 20, Color color = surface}) =>
    BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius));

/// Owns the painted surface, clipped ink, and pressed feedback together.
class TapCard extends StatelessWidget {
  const TapCard({super.key, required this.child, this.onTap, this.radius = 20});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) => Material(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          overlayColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed)
                  ? const Color(0x40000000)
                  : null),
          child: child));
}

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

const ink = Color(0xFF06251A);
const cancelSurface = Color(0xFF343B46);
const overlayInsets = EdgeInsets.symmetric(horizontal: 16, vertical: 24);

ButtonStyle secondaryAction() => TextButton.styleFrom(
    backgroundColor: cancelSurface,
    foregroundColor: primaryText,
    minimumSize: const Size(48, actionHeight),
    textStyle: buttonType(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));

ButtonStyle compactAction({bool cancel = false}) => FilledButton.styleFrom(
      backgroundColor: cancel ? cancelSurface : mint,
      foregroundColor: cancel ? primaryText : ink,
      minimumSize: const Size(48, compactActionHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: buttonType(13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

ButtonStyle backAction() => compactAction(cancel: true)
    .copyWith(backgroundColor: const WidgetStatePropertyAll(surfaceHigh));

class DialogActions extends StatelessWidget {
  const DialogActions(
      {super.key,
      required this.onCancel,
      required this.onConfirm,
      required this.confirmLabel,
      this.cancelLabel = 'Cancel'});
  final VoidCallback onCancel, onConfirm;
  final String confirmLabel, cancelLabel;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: FilledButton(
                style: compactAction(cancel: true),
                onPressed: onCancel,
                child: Text(cancelLabel, textAlign: TextAlign.center))),
        const SizedBox(width: 8),
        Expanded(
            child: FilledButton(
                style: (confirmLabel.toLowerCase().startsWith('delete') ||
                        confirmLabel.toLowerCase().startsWith('remove'))
                    ? compactAction().copyWith(
                        backgroundColor: const WidgetStatePropertyAll(danger),
                        foregroundColor:
                            const WidgetStatePropertyAll(background))
                    : compactAction(),
                onPressed: onConfirm,
                child: Text(confirmLabel, textAlign: TextAlign.center))),
      ]);
}
