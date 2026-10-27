import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('failures can be matched exhaustively', () {
    String describe(Failure f) => switch (f) {
      NetworkFailure() => 'offline',
      UnauthenticatedFailure(code: 'TOKEN_EXPIRED') => 'refresh',
      UnauthenticatedFailure() => 'sign in',
      ForbiddenFailure() => 'not allowed',
      RateLimitedFailure(:final retryAfter) => 'wait ${retryAfter?.inSeconds}',
      ValidationFailure(:final fieldErrors) => 'fix ${fieldErrors.keys.first}',
      NotFoundFailure() => 'missing',
      RejectedFailure(:final code) => 'rejected $code',
      UnexpectedFailure() => 'oops',
    };

    expect(describe(const NetworkFailure()), 'offline');
    expect(
      describe(const UnauthenticatedFailure(code: 'TOKEN_EXPIRED')),
      'refresh',
    );
    expect(
      describe(const UnauthenticatedFailure(code: 'SESSION_ENDED')),
      'sign in',
    );
    expect(
      describe(const RateLimitedFailure(retryAfter: Duration(seconds: 30))),
      'wait 30',
    );
    expect(
      describe(const ValidationFailure({'email': 'is required'})),
      'fix email',
    );
    expect(
      describe(const RejectedFailure(code: 'CODE_INVALID')),
      'rejected CODE_INVALID',
    );
  });
}
