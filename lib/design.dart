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
