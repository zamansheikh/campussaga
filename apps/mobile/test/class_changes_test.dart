import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 08:05: CSE311 08:30 (504), CSE313 11:30 (602).
final tuesdayMorning = DateTime(2026, 10, 27, 8, 5);
final tuesday = DateTime(2026, 10, 27);

Future<FakeClassGroupRepository> signedIn(
  WidgetTester tester,
  ClassGroup group,
) async {
  usePhoneScreen(tester);
  final classes = FakeClassGroupRepository()..mine.add(group);
  final (repo, _) = await registerFakes(classes: classes);
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return classes;
}

void main() {
  setUp(() => appNow = () => tuesdayMorning);
  tearDown(() => appNow = DateTime.now);

  testWidgets('the CR cancels a class for today, with a note, then undoes it', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    expect(find.text('in 25 min'), findsOneWidget);

    await scrollAndTap(tester, find.text('CSE311').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel this class'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cancel CSE311 on Tuesday'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'The teacher is on leave');
    await tester.tap(find.text('Cancel class'));
    await tester.pumpAndSettle();

    final c = classes.mine.single.changes.single;
    expect(c.kind, ChangeKind.cancelled);
    expect(c.slotId, 's-311');
    expect(c.date, tuesday);
    expect(c.note, 'The teacher is on leave');
    expect(find.textContaining('Saved.'), findsOneWidget);

    // Today now points at the next class that happens, and shows why.
    expect(find.text('in 3 h 25 min'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('The teacher is on leave'), findsOneWidget);

    // Undo.
    await scrollAndTap(tester, find.text('CSE311'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo change'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.changes, isEmpty);
    expect(find.text('in 25 min'), findsOneWidget);
  });

  testWidgets('the CR moves a class to another room for one day', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    await scrollAndTap(tester, find.text('CSE313'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change time or room'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only for Tuesday'), findsOneWidget);
    expect(find.widgetWithText(TextField, '602'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '602'), '701');
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    final c = classes.mine.single.changes.single;
    expect(c.kind, ChangeKind.moved);
    expect(c.room, '701');
    expect((c.startMin, c.endMin), (11 * 60 + 30, 13 * 60));
    expect(find.text('Changed'), findsOneWidget);
    expect(find.textContaining('Room 701'), findsOneWidget);
    // Next week is untouched.
    expect(classes.mine.single.slots[1].room, '602');
  });

  testWidgets('the CR adds an extra class from Routine', (tester) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    await tester.tap(find.text('Routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29')); // Thursday: no classes
    await tester.pumpAndSettle();
    expect(find.text('No classes on this day'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add extra class'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only for Thursday'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Course code'),
      'mat',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('MAT201').last);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    final c = classes.mine.single.changes.single;
    expect(c.kind, ChangeKind.extra);
    expect(c.courseCode, 'MAT201');
    expect(c.date, DateTime(2026, 10, 29));
    expect(find.text('MAT201'), findsOneWidget);
    expect(find.text('Extra class'), findsOneWidget);
  });

  testWidgets('classmates see the change but can\'t make one', (tester) async {
    final g = sampleGroup().copyWith(
      changes: [
        ClassChange(
          id: 'c1',
          kind: ChangeKind.cancelled,
          slotId: 's-311',
          date: tuesday,
          note: 'Exam hall booked',
        ),
      ],
    );
    await signedIn(tester, g);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Exam hall booked'), findsOneWidget);

    await scrollAndTap(tester, find.text('CSE311'));
    await tester.pumpAndSettle();
    expect(find.text('Open class group'), findsOneWidget);
    expect(find.text('Cancel this class'), findsNothing);
    expect(find.text('Undo change'), findsNothing);
    expect(find.text('Edit weekly class'), findsNothing);
  });
}
