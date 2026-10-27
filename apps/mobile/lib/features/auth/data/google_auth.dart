import 'package:campus_core/campus_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// Google sign-in through Firebase Auth. It only produces a Firebase ID
/// token; our backend checks it and starts the real session.
abstract interface class GoogleAuth {
  /// Shows the Google account picker. Returns a Firebase ID token, or null
  /// when the student cancels. Throws a [Failure] on errors.
  Future<String?> signIn();

  /// Forgets the Firebase session on this device.
  Future<void> signOut();
}

/// The right Google sign-in for this phone.
GoogleAuth platformGoogleAuth() =>
    defaultTargetPlatform == TargetPlatform.android
    ? AndroidGoogleAuth()
    : FirebaseGoogleAuth();

/// Android: the phone's own account picker (Credential Manager, through the
/// google_sign_in_android plugin), then a Firebase sign-in with that Google
/// ID token. Only the Android plugin is used: the google_sign_in iOS plugin
/// ships a Google SDK that conflicts with Firebase iOS 13.
///
/// Needs the app's signing SHA-1 in the Firebase project (debug and release)
/// and the web client ID, which the plugin reads from google-services.json.
class AndroidGoogleAuth implements GoogleAuth {
  AndroidGoogleAuth({FirebaseAuth? firebase, GoogleSignInPlatform? google})
    : _firebase = firebase ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignInPlatform.instance;

  final FirebaseAuth _firebase;
  final GoogleSignInPlatform _google;
  Future<void>? _ready;

  @override
  Future<String?> signIn() async {
    try {
      await (_ready ??= _google.init(const InitParameters()));
      final result = await _google.authenticate(const AuthenticateParameters());
      final idToken = result.authenticationTokens.idToken;
      if (idToken == null) {
        throw const RejectedFailure(
          code: 'GOOGLE_SIGN_IN_FAILED',
          message: 'No ID token from Google',
        );
      }
      final signedIn = await _firebase.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = signedIn.user;
      if (user == null) return null;
      // A new Firebase user made from this ID token can come without a
      // name, so our server can't fill in the student's name. Give Firebase
      // the Google name, then ask for a fresh token that carries it.
      final name = result.user.displayName?.trim() ?? '';
      if ((user.displayName ?? '').trim().isEmpty && name.isNotEmpty) {
        await user.updateDisplayName(name);
        return await user.getIdToken(true);
      }
      return await user.getIdToken();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw RejectedFailure(
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: '${e.code.name}: ${e.description}',
      );
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
      // Forget the chosen account too, so next time the picker shows all
      // accounts (a personal account picked by mistake isn't reused).
      await (_ready ??= _google.init(const InitParameters()));
      await _google.signOut(const SignOutParams());
      await _firebase.signOut();
    } on Object {
      // Nothing to undo if it fails; the next sign-in still works.
    }
  }
}

/// iOS (and others): Firebase Auth's own Google flow (`signInWithProvider`),
/// a secure browser sheet, no separate Google Sign-In SDK. That keeps
/// Firebase on its latest version (the google_sign_in iOS plugin ships an
/// older Google SDK that conflicts with Firebase iOS 13).
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
