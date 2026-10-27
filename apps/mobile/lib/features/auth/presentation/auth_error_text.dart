import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';

/// The student-facing, translated message for a sign-in failure.
String authErrorText(AppLocalizations l10n, Failure failure) {
  return switch (failure) {
    NetworkFailure() => l10n.errorNetwork,
    UnauthenticatedFailure(code: 'SESSION_ENDED' || 'REFRESH_INVALID') =>
      l10n.errorSessionEnded,
    UnauthenticatedFailure(code: 'GOOGLE_TOKEN_INVALID') =>
      l10n.errorGoogleFailed,
    RejectedFailure(code: 'UNIVERSITY_EMAIL_REQUIRED') =>
      l10n.errorUniversityEmailRequired,
    RejectedFailure(
      code: 'GOOGLE_SIGN_IN_FAILED' || 'GOOGLE_SIGN_IN_UNAVAILABLE',
    ) =>
      l10n.errorGoogleFailed,
    _ => l10n.errorGeneric,
  };
}
