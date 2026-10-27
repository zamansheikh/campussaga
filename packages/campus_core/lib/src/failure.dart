/// Typed errors returned by repositories, so the UI can show a friendly
/// message for each case instead of a raw exception.
sealed class Failure implements Exception {
  const Failure([this.message]);

  /// Developer-facing detail. Never shown to students as-is.
  final String? message;

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

/// No internet or the server could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// Signed out or session expired.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure([super.message]);
}

/// Signed in, but not allowed to do this.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message]);
}

/// Too many requests in a short time.
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter, String? message}) : super(message);

  final Duration? retryAfter;
}

/// Input rejected by the server, with a reason per field.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.fieldErrors, [super.message]);

  final Map<String, String> fieldErrors;
}

/// The requested item does not exist (or is hidden from this user).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

/// Anything unexpected. Reported to crash logging.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}
