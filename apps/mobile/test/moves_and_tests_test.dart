import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
import 'package:campussaga/features/reminders/data/reminder_scheduler.dart';
import 'package:campussaga/features/reminders/data/reminder_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 08:05: CSE311 08:30 (504), CSE313 11:30 (602).
final tuesdayMorning = DateTime(2026, 10, 27, 8, 5);
final tuesday = DateTime(2026, 10, 27);
final thursday = DateTime(2026, 10, 29);

Future<FakeClassGroupRepository> signedIn(
  WidgetTester tester,
  ClassGroup group, {
  Locale? locale,
}) async {
  usePhoneScreen(tester);
  final classes = FakeClassGroupRepository()..mine.add(group);
  final (repo, _) = await registerFakes(
    classes: classes,
    settings: MemorySettingsStorage(
      SettingsState(onboardingDone: true, locale: locale),
    ),
  );
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return classes;
}

Assessment classTest({
  bool canEdit = false,
  DateTime? date,
  String course = 'CSE311',
}) => Assessment(
  id: 't1',
  kind: AssessmentKind.classTest,
  courseCode: course,
  date: date ?? tuesday,
  startMin: 8 * 60 + 30,
  endMin: 9 * 60,
  room: '504',
  topics: 'Chapters 1-3',
  createdById: 'u-rafi',
  createdByName: 'Rafi',
  canEdit: canEdit,
);

void main() {
  setUp(() => appNow = () => tuesdayMorning);
  tearDown(() => appNow = DateTime.now);

  testWidgets('the CR moves a class to another day in one step', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    await scrollAndTap(tester, find.text('CSE313'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change day, time or room'));
    await tester.pumpAndSettle();
    expect(find.text('Tap to move it to another day'), findsOneWidget);

    // Pick Thursday 29 October.
    await tester.tap(find.textContaining('Only for Tuesday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This week only'), findsOneWidget);
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    final c = classes.mine.single.changes.single;
    expect(c.kind, ChangeKind.moved);
    expect(c.date, tuesday);
    expect(c.newDate, thursday);

    // Today: struck through, "Moved to Thu…"; the next class is CSE311.
    expect(find.textContaining('Moved to Thu'), findsOneWidget);
    expect(find.text('in 25 min'), findsOneWidget);

    // Thursday in Routine: the class is there, "Moved from Tue…".
    await tester.tap(find.text('Routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();
    expect(find.text('CSE313'), findsOneWidget);
    expect(find.textContaining('Moved from Tue'), findsOneWidget);

    // Undo from the moved class.
    await tester.tap(find.text('CSE313'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo change'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.changes, isEmpty);
  });

  testWidgets('a classmate adds a class test, sees it coming up, deletes it', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup());
    await scrollAndTap(tester, find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    expect(find.text('TESTS & DEADLINES'), findsOneWidget);
    await scrollAndTap(tester, find.text('Add test or deadline'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quiz'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Course code'),
      'cse31',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSE313').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Topics or details (optional)'),
      'Process scheduling',
    );
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    expect(classes.assessmentCalls, ['add quiz CSE313']);
    final t = classes.mine.single.assessments.single;
    expect(t.date, DateTime(2026, 10, 28), reason: 'tomorrow by default');
    expect(t.startMin, isNull, reason: 'CSE313 has no class on Wednesday');
    expect(t.room, '602');
    expect(find.text('Quiz · CSE313'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);

    // Today: "Coming up".
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('COMING UP'), findsOneWidget);
    expect(find.text('Quiz · CSE313'), findsOneWidget);

    // Who added it can delete it.
    await scrollAndTap(tester, find.text('Quiz · CSE313'));
    await tester.pumpAndSettle();
    expect(find.text('Process scheduling'), findsWidgets);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(classes.mine.single.assessments, isEmpty);
    expect(find.text('COMING UP'), findsNothing);
  });

  testWidgets('someone else\'s test: no edit or delete; the class shows it', (
    tester,
  ) async {
    await signedIn(tester, sampleGroup().copyWith(assessments: [classTest()]));
    // The class tile carries a badge; the class sheet lists the test.
    expect(find.text('Class test'), findsWidgets);
    await scrollAndTap(tester, find.text('CSE311').last);
    await tester.pumpAndSettle();
    // In the sheet (Today's "Coming up" behind it shows it too).
    await tester.tap(find.textContaining('Chapters 1-3').last);
    await tester.pumpAndSettle();
    expect(find.text('Added by Rafi'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(
      find.text('Only who added it or a CR can change it.'),
      findsOneWidget,
    );
  });

  testWidgets('a test the student can edit opens the editor filled in', (
    tester,
  ) async {
    final classes = await signedIn(
      tester,
      sampleGroup().copyWith(
        assessments: [classTest(canEdit: true, date: thursday)],
      ),
    );
    await scrollAndTap(tester, find.text('Class test · CSE311'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit test or deadline'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Chapters 1-3'), findsOneWidget);
    await tester.tap(find.text('Mid-term'));
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(classes.assessmentCalls, ['update t1']);
    expect(classes.mine.single.assessments.single.kind, AssessmentKind.midterm);
  });

  testWidgets('Bangla: coming up and the kinds read in Bangla', (tester) async {
    await signedIn(
      tester,
      sampleGroup().copyWith(assessments: [classTest(date: thursday)]),
      locale: const Locale('bn'),
    );
    expect(find.text('সামনে আসছে'), findsOneWidget);
    expect(find.text('ক্লাস টেস্ট · CSE311'), findsOneWidget);
  });

  testWidgets('reminders for a test: the evening before and an hour before', (
    tester,
  ) async {
    for (final (locale, evening, soon) in [
      (null, 'Tomorrow: Class test · CSE311', 'Class test soon · CSE311'),
      (
        const Locale('bn'),
        'আগামীকাল: ক্লাস টেস্ট · CSE311',
        'শিগগিরই ক্লাস টেস্ট · CSE311',
      ),
    ]) {
      usePhoneScreen(tester);
      final scheduler = MemoryReminderScheduler()..granted = true;
      final (repo, _) = await registerFakes(
        classes: FakeClassGroupRepository()
          ..mine.add(
            sampleGroup().copyWith(assessments: [classTest(date: thursday)]),
          ),
        reminderStore: MemoryReminderStore(
          const ReminderSettings(enabled: true, asked: true),
        ),
        reminderScheduler: scheduler,
        settings: MemorySettingsStorage(
          SettingsState(onboardingDone: true, locale: locale),
        ),
      );
      repo.savedUser = testUser;
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final byTitle = {for (final n in scheduler.pending) n.title: n};
      expect(byTitle[evening]?.at, DateTime(2026, 10, 28, 20));
      expect(byTitle[soon]?.at, DateTime(2026, 10, 29, 7, 30));
      expect(byTitle[soon]?.body, contains('Chapters 1-3'));
      expect(byTitle[soon]?.payload, 'g-cse');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
