import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';

import 'auth_error_text.dart';

/// The student-facing, translated message for an email-code failure.
String emailErrorText(AppLocalizations l10n, Failure failure) {
  return switch (failure) {
    ValidationFailure() => l10n.errorEmailInvalid,
    RejectedFailure(code: 'UNIVERSITY_EMAIL_REQUIRED') =>
      l10n.errorNotUniversityEmail,
    RejectedFailure(code: 'CODE_INVALID', :final details) =>
      l10n.errorCodeInvalid(
        (details?['remainingAttempts'] as num?)?.toInt() ?? 1,
      ),
    RejectedFailure(code: 'CODE_EXPIRED') => l10n.errorCodeExpired,
    RejectedFailure(code: 'EMAIL_IN_USE') => l10n.errorEmailInUse,
    RejectedFailure(code: 'ALREADY_VERIFIED') => l10n.errorAlreadyVerified,
    RejectedFailure(code: 'EMAIL_SEND_FAILED') => l10n.errorEmailSendFailed,
    RateLimitedFailure(code: 'CODE_TOO_MANY_ATTEMPTS') =>
      l10n.errorCodeTooManyAttempts,
    RateLimitedFailure(code: 'CODE_LIMIT_REACHED') => l10n.errorCodeLimit,
    RateLimitedFailure() => l10n.errorTooManyRequests,
    _ => authErrorText(l10n, failure),
  };
}

/// "0:42" for the resend countdown.
String countdownText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
