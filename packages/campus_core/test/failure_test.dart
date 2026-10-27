import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('failures can be matched exhaustively', () {
    String describe(Failure f) => switch (f) {
      NetworkFailure() => 'offline',
      UnauthenticatedFailure() => 'sign in',
      ForbiddenFailure() => 'not allowed',
      RateLimitedFailure(:final retryAfter) => 'wait ${retryAfter?.inSeconds}',
      ValidationFailure(:final fieldErrors) => 'fix ${fieldErrors.keys.first}',
      NotFoundFailure() => 'missing',
      UnexpectedFailure() => 'oops',
    };

    expect(describe(const NetworkFailure()), 'offline');
    expect(
      describe(const RateLimitedFailure(retryAfter: Duration(seconds: 30))),
      'wait 30',
    );
    expect(
      describe(const ValidationFailure({'title': 'Too short'})),
      'fix title',
    );
  });
}
