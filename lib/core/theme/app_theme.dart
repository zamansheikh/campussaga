import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App brand colours
class AppColors {
  AppColors._();

  // Primary palette – deep indigo
  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDark = Color(0xFF0031CA);
  static const Color primaryLight = Color(0xFF8187FF);

  // Accent
  static const Color accent = Color(0xFF00BCD4);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF3D5AFE),
    Color(0xFF7C4DFF),
  ];
  static const List<Color> darkGradient = [
    Color(0xFF1A237E),
    Color(0xFF4527A0),
  ];

  // Neutrals
  static const Color surface = Color(0xFFF5F6FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1C1E2D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
}

/// The [AppTheme] defines light and dark themes for the app.
sealed class AppTheme {
  static final _subThemes = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnLevel: 8,
    useM2StyleDividerInM3: true,
    defaultRadius: 14.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    elevatedButtonRadius: 14.0,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    outlinedButtonRadius: 14.0,
    filledButtonRadius: 14.0,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorIsFilled: true,
    inputDecoratorBackgroundAlpha: 20,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorRadius: 14.0,
    inputDecoratorUnfocusedHasBorder: true,
    inputDecoratorUnfocusedBorderIsColored: false,
    inputDecoratorFocusedBorderWidth: 2.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    cardRadius: 16.0,
    chipRadius: 8.0,
    popupMenuRadius: 10.0,
    popupMenuElevation: 4.0,
    alignedDropdown: true,
    appBarCenterTitle: true,
    appBarScrolledUnderElevation: 0,
    drawerIndicatorRadius: 12.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomNavigationBarMutedUnselectedLabel: false,
    bottomNavigationBarMutedUnselectedIcon: false,
    menuRadius: 10.0,
    menuElevation: 4.0,
    menuBarRadius: 0.0,
    menuBarElevation: 2.0,
    menuBarShadowColor: Color(0x00000000),
    searchBarElevation: 2.0,
    searchViewElevation: 2.0,
    searchUseGlobalShape: true,
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorRadius: 14.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailIndicatorRadius: 12.0,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
    navigationRailLabelType: NavigationRailLabelType.all,
  );

  // The defined light theme.
  static ThemeData light =
      FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xFF3D5AFE),
          primaryContainer: Color(0xFFD8DFFF),
          secondary: Color(0xFF7C4DFF),
          secondaryContainer: Color(0xFFEADDFF),
          tertiary: Color(0xFF00BCD4),
          tertiaryContainer: Color(0xFFB2EBF2),
          appBarColor: Color(0xFFD8DFFF),
          error: Color(0xFFBA1A1A),
        ),
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 3,
        subThemesData: _subThemes,
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
          keepPrimary: true,
        ),
        tones: FlexSchemeVariant.vivid.tones(Brightness.light),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.poppins().fontFamily,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      ).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1C1E2D),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F2FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0D5FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0D5FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2),
          ),
        ),
      );

  // The defined dark theme.
  static ThemeData dark =
      FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF8187FF),
          primaryContainer: Color(0xFF0031CA),
          secondary: Color(0xFFB39DDB),
          secondaryContainer: Color(0xFF4527A0),
          tertiary: Color(0xFF80DEEA),
          tertiaryContainer: Color(0xFF00838F),
          appBarColor: Color(0xFF1A1D2E),
          error: Color(0xFFFFB4AB),
        ),
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 4,
        subThemesData: _subThemes,
        keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
        tones: FlexSchemeVariant.vivid.tones(Brightness.dark),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.poppins().fontFamily,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      ).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFE8EAFF),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E2140),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D4470)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D4470)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8187FF), width: 2),
          ),
        ),
      );
}
