import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 08:05: CSE311 08:30, CSE313 11:30 (Tuesday).
final tuesdayMorning = DateTime(2026, 10, 27, 8, 5);

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

  testWidgets('a student adds a personal class; only it, then deletes it', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup());
    await tester.tap(find.text('Routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // not a CR: straight to personal
    await tester.pumpAndSettle();
    expect(find.text('Add personal class'), findsOneWidget);
    expect(find.text('Teacher'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Tuition');
    await tester.enterText(
      find.widgetWithText(TextField, 'Place'),
      'Dhanmondi',
    );
    await scrollAndTap(tester, find.text('Tue'));
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    expect(classes.personal.single.courseCode, 'Tuition');
    expect(find.text('Tuition'), findsOneWidget);
    expect(find.textContaining('Personal'), findsOneWidget);

    await scrollAndTap(tester, find.text('Tuition'));
    await tester.pumpAndSettle();
    expect(find.text('Open class group'), findsNothing);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this personal class?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(classes.personal, isEmpty);
    expect(find.text('Tuition'), findsNothing);
  });

  testWidgets('a retake student hides a course from their routine', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup());
    expect(find.text('CSE313'), findsOneWidget);
    await scrollAndTap(tester, find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3 courses in your routine'), findsOneWidget);
    await tester.tap(find.text('My courses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSE313'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.hiddenCourses, {'CSE313'});

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 courses in your routine'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('CSE313'), findsNothing, reason: 'gone from Today');
    expect(find.text('CSE311'), findsWidgets);
  });

  testWidgets('a CR gives the CR role to a classmate and removes a stranger', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    classes.membersOf['g-cse'] = const [
      GroupMember(userId: 'u1', name: 'Rafi', role: GroupRole.cr, isMe: true),
      GroupMember(userId: 'u2', name: 'Nabila Rahman', role: GroupRole.member),
      GroupMember(
        userId: 'u3',
        name: '',
        role: GroupRole.member,
        verified: false,
      ),
    ];
    await scrollAndTap(tester, find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.text('Nabila Rahman'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget, reason: 'no name set');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget, reason: 'Gmail student');

    // Menus in order: Nabila, then Student (the only CR, you, has none).
    await tester.tap(find.byIcon(Icons.more_vert).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make CR'));
    await tester.pumpAndSettle();
    expect(classes.membersOf['g-cse']![1].role, GroupRole.cr);

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from group').last);
    await tester.pumpAndSettle();
    expect(classes.membersOf['g-cse'], hasLength(2));
  });

  testWidgets('a CR starts a new semester', (tester) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    await scrollAndTap(tester, find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new semester'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Spring 2027'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    final g = classes.mine.single;
    expect(g.semester, 'Spring 2027');
    expect(g.slots, isEmpty);
    expect(find.text('Spring 2027'), findsOneWidget);
  });
}
