part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App start: restore a saved session.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// "Continue with Google" tapped.
final class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

/// Signed in another way (email code); the result is already saved.
final class AuthSignedIn extends AuthEvent {
  const AuthSignedIn(this.result);

  final SignInResult result;

  @override
  List<Object?> get props => [result.user.id];
}

/// The profile was edited (setup or edit screen); keep the copy in sync.
final class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [
    user.id,
    user.displayName,
    user.department,
    user.batch,
  ];
}

/// "Later" on the profile setup screen: don't ask again until next start.
final class AuthProfileSetupSkipped extends AuthEvent {
  const AuthProfileSetupSkipped();
}

/// "Delete my account" confirmed.
final class AuthAccountDeleteRequested extends AuthEvent {
  const AuthAccountDeleteRequested();
}

/// "Sign out" tapped.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// The server ended the session (signed out elsewhere, account deleted).
final class _AuthSessionEnded extends AuthEvent {
  const _AuthSessionEnded();
}
