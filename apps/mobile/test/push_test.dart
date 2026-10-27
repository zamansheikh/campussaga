import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/features/push/push_messaging.dart';
import 'package:campussaga/features/reminders/data/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 8, 5));
  tearDown(() => appNow = DateTime.now);

  late MemoryPushMessaging push;
  late FakeDeviceRepository devices;
  late FakeClassGroupRepository classes;
  late MemoryReminderScheduler scheduler;
  late FakeAuthRepository auth;

  Future<void> start(WidgetTester tester) async {
    usePhoneScreen(tester);
    push = MemoryPushMessaging();
    devices = FakeDeviceRepository();
    classes = FakeClassGroupRepository()..mine.add(sampleGroup());
    scheduler = MemoryReminderScheduler();
    (auth, _) = await registerFakes(
      push: push,
      devices: devices,
      classes: classes,
      reminderScheduler: scheduler,
    );
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  testWidgets('the phone registers once, again for a new language or token', (
    tester,
  ) async {
    await start(tester);
    expect(devices.registered, [('push-token-1', 'android', 'en')]);
    expect(scheduler.updatesChannel, 'Class updates');

    // Bangla: notifications must come in Bangla too.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(devices.registered.last, ('push-token-1', 'android', 'bn'));
    expect(scheduler.updatesChannel, 'ক্লাস আপডেট');

    push
      ..currentToken = 'push-token-2'
      ..refresh.add('push-token-2');
    await tester.pumpAndSettle();
    expect(devices.registered.last, ('push-token-2', 'android', 'bn'));
    expect(devices.registered, hasLength(3), reason: 'no repeats');
  });

  testWidgets('a push while the app is open is shown and refreshes', (
    tester,
  ) async {
    await start(tester);
    final before = classes.fetches;
    push.foregroundNotes.add(
      const PushNote(
        title: 'CSE311 cancelled today',
        body: 'Teacher is sick · CSE 61 · A',
        data: {'type': 'change', 'groupId': 'g-cse'},
      ),
    );
    await tester.pumpAndSettle();
    expect(scheduler.shown, [
      ('CSE311 cancelled today', 'Teacher is sick · CSE 61 · A'),
    ]);
    expect(classes.fetches, greaterThan(before));
  });

  testWidgets('tapping a push opens its group', (tester) async {
    await start(tester);
    push.openedNotes.add(
      const PushNote(data: {'type': 'announcement', 'groupId': 'g-cse'}),
    );
    await tester.pumpAndSettle();
    expect(find.text('Invite classmates'), findsOneWidget);
  });

  testWidgets('a push that opened the app opens its group', (tester) async {
    usePhoneScreen(tester);
    final p = MemoryPushMessaging()
      ..initialNote = const PushNote(data: {'groupId': 'g-cse'});
    final (repo, _) = await registerFakes(
      push: p,
      classes: FakeClassGroupRepository()..mine.add(sampleGroup()),
    );
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    expect(find.text('Invite classmates'), findsOneWidget);
  });

  testWidgets('no push token (e.g. iPhone before the APNs key): no error', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final p = MemoryPushMessaging()..currentToken = null;
    final d = FakeDeviceRepository();
    final (repo, _) = await registerFakes(push: p, devices: d);
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    expect(d.registered, isEmpty);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
