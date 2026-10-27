import 'package:flutter/material.dart';

/// Type scale. Line heights are generous because Bangla glyphs are taller.
///
/// Fonts: system default for now. Planned: bundled Inter (Latin) with
/// Noto Sans Bengali as fallback - set [fontFamily] and [fontFamilyFallback]
/// here once the font files are added.
abstract final class CsTypography {
  static const String? fontFamily = null;
  static const List<String>? fontFamilyFallback = null;

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle s(double size, double height, FontWeight w, Color c) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        height: height / size,
        fontWeight: w,
        color: c,
      );
    }

    return TextTheme(
      displaySmall: s(32, 40, FontWeight.w700, primary),
      headlineSmall: s(24, 32, FontWeight.w700, primary),
      titleLarge: s(20, 28, FontWeight.w600, primary),
      titleMedium: s(18, 26, FontWeight.w600, primary),
      titleSmall: s(16, 24, FontWeight.w600, primary),
      bodyLarge: s(16, 24, FontWeight.w400, primary),
      bodyMedium: s(14, 21, FontWeight.w400, primary),
      bodySmall: s(12, 18, FontWeight.w400, secondary),
      labelLarge: s(14, 20, FontWeight.w600, primary),
      labelMedium: s(12, 16, FontWeight.w500, secondary),
      labelSmall: s(11, 16, FontWeight.w500, secondary),
    );
  }
}
