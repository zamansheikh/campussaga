import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/dimensions.dart';
import '../tokens/typography.dart';
import 'cs_tokens.dart';

/// Builds the Material 3 themes from our tokens.
///
/// Colour mapping rule: Material's "secondary container" (selected chips,
/// segmented buttons, navigation indicator) uses the brand teal tint. The
/// amber accent is reserved for highlights such as "me too" and trending.
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
      secondary: c.primary,
      onSecondary: c.onPrimary,
      secondaryContainer: c.primaryContainer,
      onSecondaryContainer: c.onPrimaryContainer,
      tertiary: c.accent,
      onTertiary: c.onAccent,
      error: c.error,
      onError: c.onError,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceVariant,
      surfaceTint: Colors.transparent,
      outline: c.border,
      outlineVariant: c.border,
    );
    // Platform font (Roboto / San Francisco) under our sizes and colours, so
    // component styles built from it below (buttons, inputs) get it too.
    final typography = Typography.material2021();
    final text =
        (brightness == Brightness.light ? typography.black : typography.white)
            .merge(CsTypography.textTheme(c.textPrimary, c.textSecondary));
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(CsRadius.md),
    );
    const buttonSize = Size(64, CsSize.button);
    final buttonText = text.labelLarge?.copyWith(fontSize: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: text,
      fontFamilyFallback: CsTypography.fontFamilyFallback,
      splashFactory: InkSparkle.splashFactory,
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
          textStyle: buttonText,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.38),
          disabledForegroundColor: c.onPrimary.withValues(alpha: 0.9),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          backgroundColor: c.surface,
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, CsSize.minTouch),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CsSpace.md,
          vertical: 16,
        ),
        prefixIconColor: c.textSecondary,
        labelStyle: text.bodyLarge?.copyWith(color: c.textSecondary),
        hintStyle: text.bodyLarge?.copyWith(
          color: c.textSecondary.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          borderSide: BorderSide(color: c.border.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
          borderSide: BorderSide(color: c.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: c.surface,
        indicatorColor: c.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.onPrimaryContainer
                : c.textSecondary,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        minTileHeight: CsSize.minTouch,
        iconColor: c.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }
}
