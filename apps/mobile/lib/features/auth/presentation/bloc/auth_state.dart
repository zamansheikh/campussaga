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
    this.profileSetupSkipped = false,
    this.deleting = false,
  });

  final AuthStatus status;
  final UserProfile? user;
  final bool isNewUser;

  /// Why the last attempt failed; shown on the sign-in screen (or, while
  /// signed in, why deleting the account failed).
  final Failure? failure;

  /// The student chose "Later" on profile setup during this app run.
  final bool profileSetupSkipped;

  /// Account deletion in progress.
  final bool deleting;

  /// Signed in and the profile is incomplete (and not skipped), or no
  /// university yet (can't be skipped: groups need it): show profile setup.
  bool get needsProfileSetup =>
      status == AuthStatus.signedIn &&
      user != null &&
      (user!.university == null || (!user!.isComplete && !profileSetupSkipped));

  AuthState copyWith({
    UserProfile? user,
    Failure? Function()? failure,
    bool? profileSetupSkipped,
    bool? deleting,
  }) {
    return AuthState(
      status: status,
      user: user ?? this.user,
      isNewUser: isNewUser,
      failure: failure != null ? failure() : this.failure,
      profileSetupSkipped: profileSetupSkipped ?? this.profileSetupSkipped,
      deleting: deleting ?? this.deleting,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user?.id,
    user?.displayName,
    user?.department,
    user?.batch,
    user?.university?.id,
    user?.verified,
    user?.universityEmail,
    user?.photoVersion,
    user?.googlePhotoUrl,
    isNewUser,
    profileSetupSkipped,
    deleting,
    failure?.runtimeType,
    failure?.code,
  ];
}
