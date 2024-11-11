// lib/data/datasources/remote/auth_remote_datasource.dart
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
