import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/crash/crash_reporter.dart';
import 'package:campussaga/app/di.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
import 'package:campussaga/app/version/app_version.dart';
import 'package:campussaga/features/auth/data/google_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
  department: 'CSE',
  batch: '61',
);

/// Signed in for the first time: department and batch still missing.
const newUser = UserProfile(
  id: 'u2',
  email: 'mim@diu.edu.bd',
  university: University(
    id: 'uni1',
    slug: 'demo-university',
    name: 'Demo University',
  ),
  role: 'student',
  displayName: 'Mim',
);

class FakeAuthRepository implements AuthRepository {
  UserProfile? savedUser;
  Failure? googleFailure;

  /// Who Google sign-in returns (default: a complete profile).
  UserProfile googleUser = testUser;

  /// deleteAccount fails with this (account kept).
  Failure? deleteFailure;
  int deletes = 0;

  /// A non-Failure error (a bug) thrown by Google sign-in.
  Object? googleCrash;
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
    if (googleCrash != null) throw googleCrash!;
    if (googleFailure != null) throw googleFailure!;
    savedUser = googleUser;
    return SignInResult(user: googleUser, isNewUser: true);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    savedUser = null;
  }

  /// Email-code flow: [requestFailure] / [verifyFailures] make calls fail;
  /// '123456' is the right code.
  Failure? requestFailure;
  final verifyFailures = <Failure>[];
  final requested = <String>[];
  final verified = <(String, String)>[];

  @override
  Future<void> deleteAccount() async {
    deletes++;
    if (deleteFailure != null) throw deleteFailure!;
    savedUser = null;
  }

  @override
  Future<CodeSent> requestCode(String email) async {
    requested.add(email);
    if (requestFailure != null) throw requestFailure!;
    return CodeSent(
      email: email,
      university: testUser.university,
      expiresIn: const Duration(minutes: 10),
      resendAfter: const Duration(seconds: 60),
    );
  }

  @override
  Future<SignInResult> verifyCode(String email, String code) async {
    verified.add((email, code));
    if (verifyFailures.isNotEmpty) throw verifyFailures.removeAt(0);
    if (code != '123456') {
      throw const RejectedFailure(
        code: 'CODE_INVALID',
        details: {'remainingAttempts': 4},
      );
    }
    savedUser = testUser;
    return const SignInResult(user: testUser, isNewUser: false);
  }
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

class FakeProfileRepository implements ProfileRepository {
  Failure? failure;
  final updates = <(String, String, String)>[];
  final suggestionQueries = <String>[];
  List<String> suggestions = const ['CSE', 'Computer Science'];

  @override
  Future<UserProfile> updateProfile({
    required String displayName,
    required String department,
    required String batch,
  }) async {
    updates.add((displayName, department, batch));
    if (failure != null) throw failure!;
    return UserProfile(
      id: newUser.id,
      email: newUser.email,
      university: newUser.university,
      role: newUser.role,
      displayName: displayName,
      department: department,
      batch: batch,
    );
  }

  @override
  Future<List<String>> departmentSuggestions(String query) async {
    suggestionQueries.add(query);
    return suggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

class FakeAppConfigRepository implements AppConfigRepository {
  AppConfig config = const AppConfig(minSupportedBuild: 1);
  Failure? failure;
  int fetches = 0;

  @override
  Future<AppConfig> fetch() async {
    fetches++;
    if (failure != null) throw failure!;
    return config;
  }
}

/// Registers fakes in get_it for widget tests.
Future<(FakeAuthRepository, FakeGoogleAuth)> registerFakes({
  FakeProfileRepository? profile,
  FakeAppConfigRepository? config,
  SettingsStorage? settings,
  int build = 1,
}) async {
  await getIt.reset();
  final repo = FakeAuthRepository();
  final google = FakeGoogleAuth();
  getIt
    ..registerSingleton<AuthRepository>(repo)
    ..registerSingleton<GoogleAuth>(google)
    ..registerSingleton<ProfileRepository>(profile ?? FakeProfileRepository())
    ..registerSingleton<AppConfigRepository>(
      config ?? FakeAppConfigRepository(),
    )
    ..registerSingleton<SettingsStorage>(
      // Most tests start past the welcome slides.
      settings ??
          MemorySettingsStorage(const SettingsState(onboardingDone: true)),
    )
    ..registerSingleton<AppVersion>(AppVersion(version: '0.1.0', build: build))
    ..registerSingleton<CrashReporter>(MemoryCrashReporter());
  return (repo, google);
}

/// Runs the test on a phone-sized screen (390 x 844, like an iPhone 14)
/// instead of the default 800 x 600.
void usePhoneScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Scrolls [finder] into view, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}
