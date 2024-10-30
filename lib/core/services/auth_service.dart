// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<bool> isUserLoggedIn() async {
    return currentUser != null;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
