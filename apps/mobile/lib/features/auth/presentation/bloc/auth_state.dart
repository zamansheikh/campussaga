part of 'auth_bloc.dart';

enum AuthStatus {
  /// Restoring the saved session at start.
  unknown,
  signedOut,

  /// A sign-in is in progress (button shows a spinner).
  signingIn,
  signedIn,
}

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isNewUser = false,
    this.failure,
  });

  final AuthStatus status;
  final UserProfile? user;
  final bool isNewUser;

  /// Why the last attempt failed; shown on the sign-in screen.
  final Failure? failure;

  @override
  List<Object?> get props => [
    status,
    user?.id,
    user?.displayName,
    isNewUser,
    failure?.runtimeType,
    failure?.code,
  ];
}
