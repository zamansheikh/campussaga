import 'package:bloc_test/bloc_test.dart';
import 'package:campus_core/campus_core.dart';
import 'package:campussaga/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late FakeGoogleAuth google;

  setUp(() {
    repo = FakeAuthRepository();
    google = FakeGoogleAuth();
  });

  AuthBloc build() => AuthBloc(repository: repo, google: google);

  blocTest<AuthBloc, AuthState>(
    'restores a saved session',
    setUp: () => repo.savedUser = testUser,
    build: build,
    act: (b) => b.add(const AuthStarted()),
    expect: () => [
      const AuthState(status: AuthStatus.signedIn, user: testUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'no saved session means signed out',
    build: build,
    act: (b) => b.add(const AuthStarted()),
    expect: () => [const AuthState(status: AuthStatus.signedOut)],
  );

  blocTest<AuthBloc, AuthState>(
    'Google sign-in passes the Firebase token to the backend',
    build: build,
    act: (b) => b.add(const AuthGoogleRequested()),
    expect: () => [
      const AuthState(status: AuthStatus.signingIn),
      const AuthState(
        status: AuthStatus.signedIn,
        user: testUser,
        isNewUser: true,
      ),
    ],
    verify: (_) {
      expect(repo.lastGoogleToken, 'firebase-id-token');
      expect(google.signOuts, 1, reason: 'picker shows again next time');
    },
  );

  blocTest<AuthBloc, AuthState>(
    'cancelling the Google picker is not an error',
    setUp: () => google.token = null,
    build: build,
    act: (b) => b.add(const AuthGoogleRequested()),
    expect: () => [
      const AuthState(status: AuthStatus.signingIn),
      const AuthState(status: AuthStatus.signedOut),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'a personal Gmail account is refused with a clear reason',
    setUp: () => repo.googleFailure = const RejectedFailure(
      code: 'UNIVERSITY_EMAIL_REQUIRED',
    ),
    build: build,
    act: (b) => b.add(const AuthGoogleRequested()),
    expect: () => [
      const AuthState(status: AuthStatus.signingIn),
      const AuthState(
        status: AuthStatus.signedOut,
        failure: RejectedFailure(code: 'UNIVERSITY_EMAIL_REQUIRED'),
      ),
    ],
    verify: (_) => expect(google.signOuts, 1),
  );

  blocTest<AuthBloc, AuthState>(
    'sign out',
    seed: () => const AuthState(status: AuthStatus.signedIn, user: testUser),
    build: build,
    act: (b) => b.add(const AuthSignOutRequested()),
    expect: () => [const AuthState(status: AuthStatus.signedOut)],
    verify: (_) => expect(repo.signOuts, 1),
  );

  blocTest<AuthBloc, AuthState>(
    'server ending the session signs the student out',
    seed: () => const AuthState(status: AuthStatus.signedIn, user: testUser),
    build: build,
    act: (_) => repo.ended.add(null),
    expect: () => [
      const AuthState(
        status: AuthStatus.signedOut,
        failure: UnauthenticatedFailure(code: 'SESSION_ENDED'),
      ),
    ],
  );
}
