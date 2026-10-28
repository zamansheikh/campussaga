import 'dart:math' as math;

import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Every text/background pair must meet WCAG AA (4.5:1 for normal text).
  // A new color token pair that fails here must not ship.
  for (final (name, c) in [
    ('light', CsColors.light),
    ('dark', CsColors.dark),
  ]) {
    group('$name theme contrast', () {
      final pairs = <String, (Color, Color)>{
        'text on background': (c.textPrimary, c.background),
        'text on surface': (c.textPrimary, c.surface),
        'secondary text on surface': (c.textSecondary, c.surface),
        'secondary text on background': (c.textSecondary, c.background),
        'onPrimary on primary': (c.onPrimary, c.primary),
        'onPrimaryContainer on primaryContainer': (
          c.onPrimaryContainer,
          c.primaryContainer,
        ),
        'onAccent on accent': (c.onAccent, c.accent),
        'onError on error': (c.onError, c.error),
        'primary on surface': (c.primary, c.surface),
        'status open': (c.statusOpen.fg, c.statusOpen.bg),
        'status acknowledged': (
          c.statusAcknowledged.fg,
          c.statusAcknowledged.bg,
        ),
        'status in progress': (c.statusInProgress.fg, c.statusInProgress.bg),
        'status solved': (c.statusSolved.fg, c.statusSolved.bg),
        'status rejected': (c.statusRejected.fg, c.statusRejected.bg),
      };
      // Category icons (3:1 for icons) on the card and on their own tint.
      for (final cat in const [
        'academic',
        'hostel',
        'transport',
        'facilities',
        'safety',
        'administration',
        'food',
        'it',
        'other',
      ]) {
        final color = CsCategoryStyle.color(cat);
        final tint = Color.alphaBlend(color.withValues(alpha: 0.13), c.surface);
        test('category icon $cat', () {
          for (final bg in [c.surface, tint]) {
            final ratio = contrast(color, bg);
            expect(
              ratio,
              greaterThanOrEqualTo(3),
              reason: '$cat icon is ${ratio.toStringAsFixed(2)}:1',
            );
          }
        });
      }
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          final ratio = contrast(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$label is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    });
  }

  test('themes carry the token extension', () {
    expect(CsTheme.light.extension<CsTokens>(), isNotNull);
    expect(CsTheme.dark.extension<CsTokens>(), isNotNull);
  });
}
