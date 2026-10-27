import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/di.dart';
import 'package:campussaga/features/auth/data/google_auth.dart';

const testUser = UserProfile(
  id: 'u1',
  email: 'rafi@cse.demo.ac.bd',
  university: University(
    id: 'uni1',
    slug: 'demo-university',
    name: 'Demo University',
    nameBn: 'ডেমো বিশ্ববিদ্যালয়',
  ),
  role: 'student',
  displayName: 'Rafi',
);

class FakeAuthRepository implements AuthRepository {
  UserProfile? savedUser;
  Failure? googleFailure;
  String? lastGoogleToken;
  int signOuts = 0;
  final ended = StreamController<void>.broadcast();

  @override
  Stream<void> get sessionEnded => ended.stream;

  @override
  Future<UserProfile?> restoreSession() async => savedUser;

  @override
  Future<SignInResult> signInWithGoogle(String firebaseIdToken) async {
    lastGoogleToken = firebaseIdToken;
    if (googleFailure != null) throw googleFailure!;
    savedUser = testUser;
    return const SignInResult(user: testUser, isNewUser: true);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    savedUser = null;
  }

  @override
  Future<CodeSent> requestCode(String email) => throw UnimplementedError();

  @override
  Future<SignInResult> verifyCode(String email, String code) =>
      throw UnimplementedError();
}

class FakeGoogleAuth implements GoogleAuth {
  /// null = the student cancels the picker.
  String? token = 'firebase-id-token';
  Failure? failure;
  int signOuts = 0;

  @override
  Future<String?> signIn() async {
    if (failure != null) throw failure!;
    return token;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

/// Registers fakes in get_it for widget tests.
Future<(FakeAuthRepository, FakeGoogleAuth)> registerFakes() async {
  await getIt.reset();
  final repo = FakeAuthRepository();
  final google = FakeGoogleAuth();
  getIt
    ..registerSingleton<AuthRepository>(repo)
    ..registerSingleton<GoogleAuth>(google);
  return (repo, google);
}
