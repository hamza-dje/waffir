import 'package:flutter/animation.dart';

/// Shared motion tokens. Keep amount entry and calculator input instant.
abstract final class AppMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 200);
  static const reduced = Duration(milliseconds: 100);
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
}
