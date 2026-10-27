import 'package:campus_core/campus_core.dart';
import 'package:campussaga/features/auth/data/google_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class _FakeFirebase extends Fake implements FirebaseAuth {}

class _FakeGoogle extends GoogleSignInPlatform {
  GoogleSignInException? error;
  int inits = 0;

  @override
  Future<void> init(InitParameters params) async => inits++;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async => throw error!;

  // Members this test doesn't use.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('closing the account picker is not an error', () async {
    final google = _FakeGoogle()
      ..error = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    final auth = AndroidGoogleAuth(firebase: _FakeFirebase(), google: google);
    expect(await auth.signIn(), isNull);
    expect(await auth.signIn(), isNull);
    expect(google.inits, 1, reason: 'initialised once');
  });

  test('a setup problem (e.g. missing SHA-1) is reported', () async {
    final google = _FakeGoogle()
      ..error = const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Developer console is not set up correctly',
      );
    final auth = AndroidGoogleAuth(firebase: _FakeFirebase(), google: google);
    await expectLater(
      auth.signIn(),
      throwsA(
        isA<RejectedFailure>()
            .having((f) => f.code, 'code', 'GOOGLE_SIGN_IN_FAILED')
            .having(
              (f) => f.message,
              'message',
              contains('clientConfigurationError'),
            ),
      ),
    );
  });
}
