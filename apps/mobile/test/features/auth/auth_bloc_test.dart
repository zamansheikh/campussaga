import 'package:bloc_test/bloc_test.dart';
import 'package:campus_core/campus_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/features/auth/data/profile_cache.dart';
import 'package:varsitykotha/features/auth/presentation/bloc/auth_bloc.dart';

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

  group('without internet at start', () {
    late MemoryProfileCache cache;
    setUp(() {
      cache = MemoryProfileCache();
      repo.restoreFailure = const NetworkFailure();
    });
    AuthBloc offline() =>
        AuthBloc(repository: repo, google: google, profileCache: cache);

    blocTest<AuthBloc, AuthState>(
      'opens with the saved profile instead of signing out',
      setUp: () => cache.saved = testUser,
      build: offline,
      act: (b) => b.add(const AuthStarted()),
      expect: () => [
        const AuthState(status: AuthStatus.signedIn, user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'never signed in on this phone: signed out as before',
      build: offline,
      act: (b) => b.add(const AuthStarted()),
      expect: () => [
        const AuthState(
          status: AuthStatus.signedOut,
          failure: NetworkFailure(),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'back online, the session is checked again (ended: signed out)',
      setUp: () => cache.saved = testUser,
      build: offline,
      act: (b) async {
        b.add(const AuthStarted());
        await Future<void>.delayed(Duration.zero);
        repo
          ..restoreFailure = null
          ..savedUser = null; // the session ended meanwhile
        b.add(const AuthRefreshRequested());
      },
      expect: () => [
        const AuthState(status: AuthStatus.signedIn, user: testUser),
        const AuthState(status: AuthStatus.signedOut),
      ],
      verify: (_) => expect(cache.saved, isNull),
    );
  });

  test('the profile on the phone follows sign-in and sign-out', () async {
    final cache = MemoryProfileCache();
    repo.savedUser = testUser;
    final b = AuthBloc(repository: repo, google: google, profileCache: cache)
      ..add(const AuthStarted());
    await Future<void>.delayed(Duration.zero);
    expect(cache.saved?.id, testUser.id);
    b.add(const AuthSignOutRequested());
    await Future<void>.delayed(Duration.zero);
    expect(cache.saved, isNull);
    await b.close();
  });

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
      expect(repo.lastGoogleName, 'Rafi Ahmed');
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

  blocTest<AuthBloc, AuthState>(
    'an unexpected error never leaves sign-in spinning',
    setUp: () => repo.googleCrash = ArgumentError('No host specified in URI'),
    build: build,
    act: (b) => b.add(const AuthGoogleRequested()),
    expect: () => [
      const AuthState(status: AuthStatus.signingIn),
      const AuthState(
        status: AuthStatus.signedOut,
        failure: UnexpectedFailure(),
      ),
    ],
    errors: () => [isA<ArgumentError>()],
  );

  blocTest<AuthBloc, AuthState>(
    'an incomplete profile needs setup until saved or skipped',
    seed: () => const AuthState(status: AuthStatus.signedIn, user: newUser),
    build: build,
    act: (b) => b.add(const AuthProfileSetupSkipped()),
    verify: (b) {
      expect(
        const AuthState(
          status: AuthStatus.signedIn,
          user: newUser,
        ).needsProfileSetup,
        isTrue,
      );
      expect(b.state.needsProfileSetup, isFalse);
      expect(b.state.profileSetupSkipped, isTrue);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'profile updates replace the signed-in user',
    seed: () => const AuthState(status: AuthStatus.signedIn, user: newUser),
    build: build,
    act: (b) => b.add(const AuthProfileUpdated(testUser)),
    verify: (b) {
      expect(b.state.user?.department, 'CSE');
      expect(b.state.needsProfileSetup, isFalse);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'deleting the account signs out',
    seed: () => const AuthState(status: AuthStatus.signedIn, user: testUser),
    build: build,
    act: (b) => b.add(const AuthAccountDeleteRequested()),
    expect: () => [
      const AuthState(
        status: AuthStatus.signedIn,
        user: testUser,
        deleting: true,
      ),
      const AuthState(status: AuthStatus.signedOut),
    ],
    verify: (_) => expect(repo.deletes, 1),
  );

  blocTest<AuthBloc, AuthState>(
    'if deleting fails the student stays signed in and sees why',
    setUp: () => repo.deleteFailure = const NetworkFailure(),
    seed: () => const AuthState(status: AuthStatus.signedIn, user: testUser),
    build: build,
    act: (b) => b.add(const AuthAccountDeleteRequested()),
    expect: () => [
      const AuthState(
        status: AuthStatus.signedIn,
        user: testUser,
        deleting: true,
      ),
      const AuthState(
        status: AuthStatus.signedIn,
        user: testUser,
        failure: NetworkFailure(),
      ),
    ],
  );
}
