import 'package:campus_core/campus_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Google sign-in through Firebase Auth. It only produces a Firebase ID
/// token; our backend checks it and starts the real session.
abstract interface class GoogleAuth {
  /// Shows the Google account picker. Returns a Firebase ID token, or null
  /// when the student cancels. Throws a [Failure] on errors.
  Future<String?> signIn();

  /// Forgets the Firebase session on this device.
  Future<void> signOut();
}

/// Uses Firebase Auth's own Google flow (`signInWithProvider`): a secure
/// browser sheet on Android and iOS, no separate Google Sign-In SDK. That
/// keeps Firebase on its latest version (the google_sign_in iOS plugin still
/// ships an older Google SDK that conflicts with Firebase iOS 13).
class FirebaseGoogleAuth implements GoogleAuth {
  FirebaseGoogleAuth({FirebaseAuth? firebase})
    : _firebase = firebase ?? FirebaseAuth.instance;

  final FirebaseAuth _firebase;

  static const _cancelCodes = {
    'canceled',
    'cancelled',
    'web-context-canceled',
    'web-context-cancelled',
  };

  @override
  Future<String?> signIn() async {
    // Always show the account chooser, so a student who picked a personal
    // account by mistake can pick their university account next time.
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      final credential = await _firebase.signInWithProvider(provider);
      return await credential.user?.getIdToken();
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return null;
      if (e.code == 'network-request-failed') {
        throw NetworkFailure(message: e.message);
      }
      throw RejectedFailure(
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: '${e.code}: ${e.message}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebase.signOut();
    } on Object {
      // Nothing to undo if it fails; the next sign-in still works.
    }
  }
}
