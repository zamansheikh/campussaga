import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'brand.dart';

/// Colors of one issue status: text/icon, chip background and border.
@immutable
class CsStatusColors {
  const CsStatusColors({
    required this.fg,
    required this.bg,
    required this.border,
  });

  final Color fg;
  final Color bg;
  final Color border;

  static CsStatusColors lerp(CsStatusColors a, CsStatusColors b, double t) {
    return CsStatusColors(
      fg: Color.lerp(a.fg, b.fg, t)!,
      bg: Color.lerp(a.bg, b.bg, t)!,
      border: Color.lerp(a.border, b.border, t)!,
    );
  }
}

/// Semantic colors. Widgets use these names, never raw hex values.
@immutable
class CsColors {
  const CsColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.error,
    required this.onError,
    required this.statusOpen,
    required this.statusAcknowledged,
    required this.statusInProgress,
    required this.statusSolved,
    required this.statusRejected,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color error;
  final Color onError;

  final CsStatusColors statusOpen;
  final CsStatusColors statusAcknowledged;
  final CsStatusColors statusInProgress;
  final CsStatusColors statusSolved;
  final CsStatusColors statusRejected;

  static const CsColors light = CsColors(
    primary: CsBrand.primaryLight,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCCFBF1),
    onPrimaryContainer: Color(0xFF042F2E),
    accent: CsBrand.accentLight,
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    border: Color(0xFFE2E8F0),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    statusOpen: CsStatusColors(
      fg: Color(0xFF1D4ED8),
      bg: Color(0xFFDBEAFE),
      border: Color(0xFFBFDBFE),
    ),
    statusAcknowledged: CsStatusColors(
      fg: Color(0xFF6D28D9),
      bg: Color(0xFFEDE9FE),
      border: Color(0xFFDDD6FE),
    ),
    statusInProgress: CsStatusColors(
      fg: Color(0xFFB45309),
      bg: Color(0xFFFEF3C7),
      border: Color(0xFFFDE68A),
    ),
    statusSolved: CsStatusColors(
      fg: Color(0xFF15803D),
      bg: Color(0xFFDCFCE7),
      border: Color(0xFFBBF7D0),
    ),
    statusRejected: CsStatusColors(
      fg: Color(0xFF475569),
      bg: Color(0xFFF1F5F9),
      border: Color(0xFFE2E8F0),
    ),
  );

  static const CsColors dark = CsColors(
    primary: CsBrand.primaryDark,
    onPrimary: Color(0xFF042F2E),
    primaryContainer: Color(0xFF134E4A),
    onPrimaryContainer: Color(0xFFCCFBF1),
    accent: CsBrand.accentDark,
    onAccent: Color(0xFF1C1917),
    background: Color(0xFF0B1220),
    surface: Color(0xFF111A2B),
    surfaceVariant: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF273449),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    statusOpen: CsStatusColors(
      fg: Color(0xFF93C5FD),
      bg: Color(0xFF172554),
      border: Color(0xFF1E3A8A),
    ),
    statusAcknowledged: CsStatusColors(
      fg: Color(0xFFC4B5FD),
      bg: Color(0xFF2E1065),
      border: Color(0xFF4C1D95),
    ),
    statusInProgress: CsStatusColors(
      fg: Color(0xFFFCD34D),
      bg: Color(0xFF451A03),
      border: Color(0xFF78350F),
    ),
    statusSolved: CsStatusColors(
      fg: Color(0xFF86EFAC),
      bg: Color(0xFF052E16),
      border: Color(0xFF14532D),
    ),
    statusRejected: CsStatusColors(
      fg: Color(0xFFCBD5E1),
      bg: Color(0xFF1E293B),
      border: Color(0xFF334155),
    ),
  );

  static CsColors lerp(CsColors a, CsColors b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return CsColors(
      primary: c(a.primary, b.primary),
      onPrimary: c(a.onPrimary, b.onPrimary),
      primaryContainer: c(a.primaryContainer, b.primaryContainer),
      onPrimaryContainer: c(a.onPrimaryContainer, b.onPrimaryContainer),
      accent: c(a.accent, b.accent),
      onAccent: c(a.onAccent, b.onAccent),
      background: c(a.background, b.background),
      surface: c(a.surface, b.surface),
      surfaceVariant: c(a.surfaceVariant, b.surfaceVariant),
      textPrimary: c(a.textPrimary, b.textPrimary),
      textSecondary: c(a.textSecondary, b.textSecondary),
      border: c(a.border, b.border),
      error: c(a.error, b.error),
      onError: c(a.onError, b.onError),
      statusOpen: CsStatusColors.lerp(a.statusOpen, b.statusOpen, t),
      statusAcknowledged: CsStatusColors.lerp(
        a.statusAcknowledged,
        b.statusAcknowledged,
        t,
      ),
      statusInProgress: CsStatusColors.lerp(
        a.statusInProgress,
        b.statusInProgress,
        t,
      ),
      statusSolved: CsStatusColors.lerp(a.statusSolved, b.statusSolved, t),
      statusRejected: CsStatusColors.lerp(
        a.statusRejected,
        b.statusRejected,
        t,
      ),
    );
  }
}
