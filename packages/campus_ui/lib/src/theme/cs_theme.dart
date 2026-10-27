import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/dimensions.dart';
import '../tokens/typography.dart';
import 'cs_tokens.dart';

/// Builds the Material 3 themes from our tokens.
abstract final class CsTheme {
  static ThemeData get light => _build(CsColors.light, Brightness.light);
  static ThemeData get dark => _build(CsColors.dark, Brightness.dark);

  static ThemeData _build(CsColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.error,
      onError: c.onError,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.surfaceVariant,
      outline: c.border,
      outlineVariant: c.border,
    );
    final text = CsTypography.textTheme(c.textPrimary, c.textSecondary);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(CsRadius.md),
    );
    const buttonSize = Size(64, CsSize.minTouch);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      textTheme: text,
      fontFamilyFallback: CsTypography.fontFamilyFallback,
      extensions: [CsTokens(colors: c)],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.lg),
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          side: BorderSide(color: c.border),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.sm),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        minTileHeight: CsSize.minTouch,
        contentPadding: EdgeInsets.symmetric(horizontal: CsSpace.md),
      ),
    );
  }
}
