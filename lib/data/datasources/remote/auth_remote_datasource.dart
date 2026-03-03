// lib/data/datasources/remote/auth_remote_datasource.dart
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSource({required this.firebaseAuth});

  Future<String> signUpUser(UserParams user) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: user.email,
      password: user.password,
    );
    return userCredential.user!.uid;
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Use the new GoogleSignIn v7.x API
      final google = GoogleSignIn.instance;
      await google.initialize();

      final account = await google.authenticate();
      final auth = account.authentication;

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<String> signInUser(UserParams user) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: user.email,
      password: user.password,
    );
    return userCredential.user!.uid;
  }

  Future<void> signOutUser() async {
    await firebaseAuth.signOut();
  }
}
