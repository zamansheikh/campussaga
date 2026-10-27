import 'auth_models.dart';

/// Sign-in and session for the current student. Every method throws a
/// `Failure` (see failure.dart) on error.
abstract interface class AuthRepository {
  /// Restores a saved session at app start. Returns the profile, or null
  /// when signed out (or the saved session is no longer valid).
  Future<UserProfile?> restoreSession();

  /// Sends a 6-digit code to a university email address.
  Future<CodeSent> requestCode(String email);

  /// Signs in with the emailed code.
  Future<SignInResult> verifyCode(String email, String code);

  /// Signs in with a Firebase ID token from Google sign-in.
  Future<SignInResult> signInWithGoogle(String firebaseIdToken);

  /// Ends this device's session (best effort on the server) and forgets it.
  Future<void> signOut();

  /// Fires when the server ends the session on its own (signed out
  /// elsewhere, account deleted, stolen token detected).
  Stream<void> get sessionEnded;
}
