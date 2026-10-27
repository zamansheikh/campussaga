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

/// "Sign out" tapped.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// The server ended the session (signed out elsewhere, account deleted).
final class _AuthSessionEnded extends AuthEvent {
  const _AuthSessionEnded();
}
