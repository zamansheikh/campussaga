/// Typed errors returned by repositories, so the UI can show a friendly
/// message for each case instead of a raw exception.
///
/// [code] is the backend's stable error code (e.g. `CODE_INVALID`,
/// `UNIVERSITY_EMAIL_REQUIRED`). Screens branch on it to pick a translated
/// message; the list of codes lives in docs/ARCHITECTURE.md.
sealed class Failure implements Exception {
  const Failure({this.code, this.message});

  /// Backend error code, or null for client-side failures (no internet).
  final String? code;

  /// Developer-facing detail. Never shown to students as-is.
  final String? message;

  @override
  String toString() =>
      '$runtimeType(${code ?? ''}${message == null ? '' : ': $message'})';
}

/// No internet or the server could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.code, super.message});
}

/// Signed out, session expired or ended. `TOKEN_EXPIRED` means: refresh and
/// retry; any other code means: sign in again.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({super.code, super.message});
}

/// Signed in (or identified), but not allowed to do this.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.code, super.message});
}

/// Too many requests in a short time.
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter, super.code, super.message});

  final Duration? retryAfter;
}

/// Input rejected, with a reason per field (field name -> reason).
final class ValidationFailure extends Failure {
  const ValidationFailure(this.fieldErrors, {super.code, super.message});

  final Map<String, String> fieldErrors;
}

/// The requested item does not exist (or is hidden from this user).
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.code, super.message});
}

/// A business rule said no (e.g. `CODE_INVALID`, `CODE_EXPIRED`). Read [code].
final class RejectedFailure extends Failure {
  const RejectedFailure({
    required String super.code,
    super.message,
    this.details,
  });

  final Map<String, Object?>? details;
}

/// Anything unexpected. Reported to crash logging.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.code, super.message});
}
