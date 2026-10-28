import 'dart:ui';

/// Everything that identifies the brand, in one place.
///
/// The product name and logo will change later. Rebranding means editing
/// this file (plus the native app labels and launcher icons listed in
/// docs/DESIGN_SYSTEM.md, "Rebranding"). Screens and components never
/// hard-code a brand value.
///
/// The colors are chosen for the product's context (a calm, trustworthy
/// tool for students), not taken from the current logo.
abstract final class CsBrand {
  /// Display name used inside the app (titles, about screen).
  static const String appName = 'VarsityKotha';

  /// Main brand hue: deep teal. Reads as trust and calm, stays clear of
  /// alarm red and of social-media blue.
  static const Color primaryLight = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF5EEAD4);

  /// Secondary hue for "me too", trending and highlights: warm amber.
  static const Color accentLight = Color(0xFFB45309);
  static const Color accentDark = Color(0xFFFBBF24);
}
