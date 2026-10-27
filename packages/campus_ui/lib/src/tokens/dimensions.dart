import 'package:flutter/animation.dart';

/// 4-point spacing scale.
abstract final class CsSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Side padding of every screen.
  static const double screen = md;
}

abstract final class CsRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

abstract final class CsMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class CsSize {
  /// Minimum touch target (accessibility).
  static const double minTouch = 48;

  /// Height of primary buttons.
  static const double button = 52;

  /// Max content width on tablets and landscape.
  static const double contentMaxWidth = 480;
}
