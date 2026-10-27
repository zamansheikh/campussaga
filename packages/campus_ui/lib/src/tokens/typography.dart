import 'package:flutter/material.dart';

/// Type scale. Line heights are generous because Bangla glyphs are taller.
///
/// Fonts: Latin text uses the platform font (Roboto / SF); Bangla falls
/// back to the bundled Noto Sans Bengali, so it renders the same on every
/// phone, including ones with poor built-in Bangla fonts.
abstract final class CsTypography {
  static const String? fontFamily = null;

  /// Fonts bundled in this package are addressed as `packages/<pkg>/<family>`.
  static const String banglaFamily = 'packages/campus_ui/NotoSansBengali';
  static const List<String> fontFamilyFallback = [banglaFamily];

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
