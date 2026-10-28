import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/app/settings/bloc/settings_state.dart';
import 'package:varsitykotha/app/settings/settings_storage.dart';
import 'package:varsitykotha/features/reminders/data/phone_info.dart';
import 'package:varsitykotha/features/reminders/data/reminder_scheduler.dart';
import 'package:varsitykotha/features/reminders/data/reminder_store.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 08:05: CSE311 08:30, CSE313 11:30, MAT201 Wed 09:00.
final tuesdayMorning = DateTime(2026, 10, 27, 8, 5);

Future<(MemoryReminderScheduler, MemoryReminderStore, FakeAuthRepository)>
start(
  WidgetTester tester, {
  ReminderSettings saved = const ReminderSettings(),
  bool granted = false,
  bool grantOnRequest = true,
  bool exact = true,
  Locale? locale,
}) async {
  usePhoneScreen(tester);
  final scheduler = MemoryReminderScheduler()
    ..granted = granted
    ..grantOnRequest = grantOnRequest
    ..exact = exact;
  final store = MemoryReminderStore(saved);
  final (repo, _) = await registerFakes(
    classes: FakeClassGroupRepository()..mine.add(sampleGroup()),
    reminderStore: store,
    reminderScheduler: scheduler,
    settings: MemorySettingsStorage(
      SettingsState(onboardingDone: true, locale: locale),
    ),
  );
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return (scheduler, store, repo);
}

void main() {
  setUp(() => appNow = () => tuesdayMorning);
  tearDown(() => appNow = DateTime.now);

  testWidgets('Today asks once; "Turn on" schedules the reminders', (
    tester,
  ) async {
    final (scheduler, store, _) = await start(tester);
    expect(find.text('Never miss a class'), findsOneWidget);
    expect(scheduler.pending, isEmpty);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(scheduler.requests, 1);
    expect(find.text('Never miss a class'), findsNothing);
    expect(store.saved.enabled, isTrue);
    final first = scheduler.pending.first;
    expect(first.title, 'CSE311 in 10 min');
    expect(first.body, startsWith('Database Systems · Room 504 · 8:30'));
    expect(first.at, DateTime(2026, 10, 27, 8, 20));
    // 3 classes a week for two weeks.
    expect(scheduler.pending, hasLength(6));
  });

  testWidgets('"Not now" hides the prompt and schedules nothing', (
    tester,
  ) async {
    final (scheduler, store, _) = await start(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Never miss a class'), findsNothing);
    expect(store.saved.asked, isTrue);
    expect(scheduler.pending, isEmpty);
    expect(scheduler.requests, 0);
  });

  testWidgets('blocked notifications are explained', (tester) async {
    final (scheduler, _, _) = await start(tester, grantOnRequest: false);
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(scheduler.pending, isEmpty);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.text('Class reminders'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications are off'), findsOneWidget);

    // Allowed in Settings, then "Try again".
    scheduler.grantOnRequest = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications are off'), findsNothing);
    expect(scheduler.pending, isNotEmpty);
  });

  testWidgets('choose how early, mute a course, turn off', (tester) async {
    final (scheduler, store, _) = await start(
      tester,
      saved: const ReminderSettings(enabled: true, asked: true),
      granted: true,
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('10 min before'), findsOneWidget);
    await tester.tap(find.text('Class reminders'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('30 min before'));
    await tester.pumpAndSettle();
    // 08:00 for the 08:30 class has passed: the 11:30 one is next.
    expect(scheduler.pending.first.title, 'CSE313 in 30 min');
    expect(scheduler.pending.first.at, DateTime(2026, 10, 27, 11));

    await scrollAndTap(tester, find.text('CSE313'));
    await tester.pumpAndSettle();
    expect(store.saved.muted, {'CSE313'});
    expect(
      scheduler.pending.map((r) => r.title),
      everyElement(isNot(contains('CSE313'))),
    );

    await tester.tap(find.text('Remind me before each class'));
    await tester.pumpAndSettle();
    expect(scheduler.pending, isEmpty);
    expect(store.saved.enabled, isFalse);
  });

  testWidgets('Xiaomi and similar phones get a battery guide', (tester) async {
    usePhoneScreen(tester);
    final phone = MemoryPhoneInfo('Xiaomi');
    final (repo, _) = await registerFakes(
      classes: FakeClassGroupRepository()..mine.add(sampleGroup()),
      reminderStore: MemoryReminderStore(
        const ReminderSettings(enabled: true, asked: true),
      ),
      reminderScheduler: MemoryReminderScheduler()..granted = true,
      phone: phone,
    );
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Reminders arriving late?'), findsOneWidget);
    expect(find.textContaining('Xiaomi phones can stop apps'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    expect(phone.opened, 1);
  });

  testWidgets('Android: asks to allow on-time alarms when needed', (
    tester,
  ) async {
    final (scheduler, _, _) = await start(
      tester,
      saved: const ReminderSettings(enabled: true, asked: true),
      granted: true,
      exact: false,
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Remind on time'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(scheduler.exact, isTrue);
  });

  testWidgets('notifications are in Bangla when the app is', (tester) async {
    final (scheduler, _, _) = await start(
      tester,
      saved: const ReminderSettings(enabled: true, asked: true),
      granted: true,
      locale: const Locale('bn'),
    );
    expect(scheduler.pending.first.title, '১০ মিনিট পর CSE311');
    expect(scheduler.pending.first.body, contains('রুম 504'));
  });

  testWidgets('signing out removes the reminders', (tester) async {
    final (scheduler, _, _) = await start(
      tester,
      saved: const ReminderSettings(enabled: true, asked: true),
      granted: true,
    );
    expect(scheduler.pending, isNotEmpty);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(scheduler.pending, isEmpty);
  });
}
