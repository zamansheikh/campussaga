import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/crash/crash_reporter.dart';
import 'package:campussaga/app/di.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
import 'package:campussaga/app/version/app_version.dart';
import 'package:campussaga/features/auth/data/google_auth.dart';
import 'package:campussaga/features/classes/data/routine_cache.dart';
import 'package:campussaga/features/reminders/data/reminder_scheduler.dart';
import 'package:campussaga/features/reminders/data/reminder_store.dart';
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
  FakeClassGroupRepository? classes,
  RoutineCache? routineCache,
  ReminderStore? reminderStore,
  ReminderScheduler? reminderScheduler,
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
    ..registerSingleton<CrashReporter>(MemoryCrashReporter())
    ..registerSingleton<ClassGroupRepository>(
      classes ?? FakeClassGroupRepository(),
    )
    ..registerSingleton<RoutineCache>(routineCache ?? MemoryRoutineCache())
    ..registerSingleton<ReminderStore>(reminderStore ?? MemoryReminderStore())
    ..registerSingleton<ReminderScheduler>(
      reminderScheduler ?? MemoryReminderScheduler(),
    );
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

/// In-memory class groups. [others] are groups the student can join by code.
class FakeClassGroupRepository implements ClassGroupRepository {
  final mine = <ClassGroup>[];
  final others = <String, ClassGroup>{};

  /// Every call fails with this (e.g. NetworkFailure: offline).
  Failure? failure;
  var _ids = 0;

  String _id(String p) => '$p${++_ids}';

  void _check() {
    if (failure != null) throw failure!;
  }

  ClassGroup _mine(String id) => mine.firstWhere(
    (g) => g.id == id,
    orElse: () => throw const NotFoundFailure(code: 'GROUP_NOT_FOUND'),
  );

  void _put(ClassGroup g) {
    final i = mine.indexWhere((x) => x.id == g.id);
    if (i < 0) {
      mine.add(g);
    } else {
      mine[i] = g;
    }
  }

  @override
  Future<List<ClassGroup>> myGroups() async {
    _check();
    return List.of(mine);
  }

  @override
  Future<ClassGroup> create(GroupDraft d) async {
    _check();
    final g = ClassGroup(
      id: _id('g'),
      department: d.department,
      batch: d.batch,
      section: d.section,
      semester: d.semester,
      joinCode: 'KQWZRT',
      role: GroupRole.cr,
      memberCount: 1,
    );
    mine.add(g);
    return g;
  }

  @override
  Future<GroupPreview> preview(String code) async {
    _check();
    final g = others[code] ?? mine.where((x) => x.joinCode == code).firstOrNull;
    if (g == null) throw const NotFoundFailure(code: 'GROUP_NOT_FOUND');
    return GroupPreview(
      department: g.department,
      batch: g.batch,
      section: g.section,
      semester: g.semester,
      memberCount: g.memberCount,
      classCount: g.slots.length,
      isMember: mine.any((x) => x.id == g.id),
    );
  }

  @override
  Future<ClassGroup> join(String code) async {
    _check();
    final g = others.remove(code);
    if (g == null) throw const NotFoundFailure(code: 'GROUP_NOT_FOUND');
    final joined = g.copyWith(memberCount: g.memberCount + 1);
    mine.add(joined);
    return joined;
  }

  @override
  Future<ClassGroup> update(String id, GroupDraft d) async {
    _check();
    final old = _mine(id);
    final g = ClassGroup(
      id: id,
      department: d.department,
      batch: d.batch,
      section: d.section,
      semester: d.semester,
      joinCode: old.joinCode,
      role: old.role,
      memberCount: old.memberCount,
      slots: old.slots,
    );
    _put(g);
    return g;
  }

  @override
  Future<void> delete(String id) async {
    _check();
    mine.removeWhere((g) => g.id == id);
  }

  @override
  Future<void> leave(String id) async {
    _check();
    final g = _mine(id);
    if (g.isCr && g.memberCount > 1) {
      throw const RejectedFailure(code: 'CR_CANNOT_LEAVE');
    }
    mine.remove(g);
  }

  ClassSlot _slot(String id, SlotDraft d) => ClassSlot(
    id: id,
    courseCode: d.courseCode,
    courseTitle: d.courseTitle,
    teacher: d.teacher,
    room: d.room,
    weekday: d.weekday,
    startMin: d.startMin,
    endMin: d.endMin,
    kind: d.kind,
  );

  @override
  Future<ClassSlot> addSlot(String groupId, SlotDraft d) async {
    _check();
    final g = _mine(groupId);
    final s = _slot(_id('s'), d);
    _put(g.copyWith(slots: [...g.slots, s]));
    return s;
  }

  @override
  Future<ClassSlot> updateSlot(
    String groupId,
    String slotId,
    SlotDraft d,
  ) async {
    _check();
    final g = _mine(groupId);
    final s = _slot(slotId, d);
    _put(g.copyWith(slots: [for (final x in g.slots) x.id == slotId ? s : x]));
    return s;
  }

  @override
  Future<void> deleteSlot(String groupId, String slotId) async {
    _check();
    final g = _mine(groupId);
    _put(g.copyWith(slots: g.slots.where((x) => x.id != slotId).toList()));
  }

  @override
  Future<ClassChange> addChange(String groupId, ChangeDraft d) async {
    _check();
    final g = _mine(groupId);
    final c = ClassChange(
      id: _id('c'),
      kind: d.kind,
      slotId: d.slotId,
      date: d.date,
      courseCode: d.courseCode,
      courseTitle: d.courseTitle,
      teacher: d.teacher,
      classKind: d.classKind,
      room: d.room,
      startMin: d.startMin,
      endMin: d.endMin,
      note: d.note,
    );
    _put(
      g.copyWith(
        changes: [
          ...g.changes.where(
            (x) =>
                d.slotId == null || !(x.slotId == d.slotId && x.date == d.date),
          ),
          c,
        ],
      ),
    );
    return c;
  }

  @override
  Future<void> deleteChange(String groupId, String changeId) async {
    _check();
    final g = _mine(groupId);
    _put(
      g.copyWith(changes: g.changes.where((x) => x.id != changeId).toList()),
    );
  }
}

/// A CSE 61 group with three classes: Tuesday 08:30 and 11:30, Wednesday 09:00.
ClassGroup sampleGroup({
  GroupRole role = GroupRole.member,
  String id = 'g-cse',
}) => ClassGroup(
  id: id,
  department: 'CSE',
  batch: '61',
  section: 'A',
  semester: 'Fall 2026',
  joinCode: 'ABCDEF',
  role: role,
  memberCount: 41,
  slots: const [
    ClassSlot(
      id: 's-311',
      courseCode: 'CSE311',
      courseTitle: 'Database Systems',
      teacher: 'Dr. Rahman',
      room: '504',
      weekday: DateTime.tuesday,
      startMin: 8 * 60 + 30,
      endMin: 10 * 60,
    ),
    ClassSlot(
      id: 's-313',
      courseCode: 'CSE313',
      courseTitle: 'Operating Systems',
      room: '602',
      weekday: DateTime.tuesday,
      startMin: 11 * 60 + 30,
      endMin: 13 * 60,
      kind: ClassKind.lab,
    ),
    ClassSlot(
      id: 's-mat',
      courseCode: 'MAT201',
      weekday: DateTime.wednesday,
      startMin: 9 * 60,
      endMin: 10 * 60 + 30,
    ),
  ],
);
