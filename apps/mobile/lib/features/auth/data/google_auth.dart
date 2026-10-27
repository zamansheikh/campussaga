import 'package:campus_core/campus_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google sign-in through Firebase Auth. It only produces a Firebase ID
/// token; our backend checks it and starts the real session.
abstract interface class GoogleAuth {
  /// Shows the Google account picker. Returns a Firebase ID token, or null
  /// when the student cancels. Throws a [Failure] on errors.
  Future<String?> signIn();

  /// Forgets the Google/Firebase account on this device, so the picker
  /// shows again next time (e.g. after choosing a personal account by mistake).
  Future<void> signOut();
}

class FirebaseGoogleAuth implements GoogleAuth {
  FirebaseGoogleAuth({
    GoogleSignIn? google,
    FirebaseAuth? firebase,
    this.iosClientId,
  }) : _google = google ?? GoogleSignIn.instance,
       _firebase = firebase ?? FirebaseAuth.instance;

  final GoogleSignIn _google;
  final FirebaseAuth _firebase;

  /// iOS needs its OAuth client id (from firebase_options.dart). Android
  /// reads everything from google-services.json.
  final String? iosClientId;

  Future<void>? _init;

  Future<void> _ensureInitialized() => _init ??= _google.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS ? iosClientId : null,
  );

  @override
  Future<String?> signIn() async {
    await _ensureInitialized();
    final GoogleSignInAccount account;
    try {
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw RejectedFailure(
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: '${e.code}: ${e.description}',
      );
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const RejectedFailure(
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: 'Google returned no ID token',
      );
    }
    try {
      final credential = await _firebase.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return await credential.user?.getIdToken();
    } on FirebaseAuthException catch (e) {
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
      await _ensureInitialized();
      await _google.signOut();
    } on Object {
      // Nothing to undo if it fails; the next sign-in still works.
    }
  }
}
