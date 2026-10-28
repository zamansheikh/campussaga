import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/features/classes/presentation/pages/find_class_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// EEE 58 · B: another findable section of the same university.
ClassGroup eeeGroup() => const ClassGroup(
  id: 'g-eee',
  department: 'EEE',
  batch: '58',
  section: 'B',
  semester: 'Fall 2026',
  joinCode: 'MNPQRS',
  role: GroupRole.member,
  memberCount: 12,
  slots: [
    ClassSlot(
      id: 's-eee',
      courseCode: 'EEE201',
      teacher: 'Ms. Akter',
      weekday: DateTime.sunday,
      startMin: 10 * 60,
      endMin: 11 * 60,
    ),
  ],
);

Future<FakeClassGroupRepository> signedIn(
  WidgetTester tester, {
  List<ClassGroup> mine = const [],
  Map<String, ClassGroup> others = const {},
}) async {
  usePhoneScreen(tester);
  final classes = FakeClassGroupRepository()
    ..mine.addAll(mine)
    ..others.addAll(others);
  final (repo, _) = await registerFakes(classes: classes);
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return classes;
}

/// Types into the search box and waits out the debounce.
Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(FindClassPage.debounce);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 8, 5));
  tearDown(() => appNow = DateTime.now);

  testWidgets('find your class: search, preview, add only some courses', (
    tester,
  ) async {
    final classes = await signedIn(
      tester,
      others: {'ABCDEF': sampleGroup(), 'MNPQRS': eeeGroup()},
    );

    // Today's empty card leads with search; the code stays one tap away.
    expect(find.text('Join with a code'), findsOneWidget);
    await tester.tap(find.text('Find your class'));
    await tester.pumpAndSettle();

    // Every findable section first, with its courses and CR.
    expect(find.text('CSE 61 · A'), findsOneWidget);
    expect(find.text('EEE 58 · B'), findsOneWidget);
    expect(find.text('CSE311'), findsOneWidget);
    expect(find.textContaining('CR: Rafi'), findsNWidgets(2));

    // By course code (any spacing), by teacher, or nothing.
    await search(tester, 'cse 311');
    expect(classes.searches.last, 'cse 311');
    await search(tester, 'cse311');
    expect(find.text('CSE 61 · A'), findsOneWidget);
    expect(find.text('EEE 58 · B'), findsNothing);
    await search(tester, 'akter');
    expect(find.text('EEE 58 · B'), findsOneWidget);
    expect(find.text('CSE 61 · A'), findsNothing);
    await search(tester, 'physics');
    expect(find.text('No class found'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);

    // Open the CSE routine: courses to tick, then the week.
    await search(tester, 'cse 61');
    await tester.tap(find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    expect(find.text('Database Systems · Dr. Rahman'), findsOneWidget);
    expect(find.text('TUESDAY'), findsOneWidget);
    expect(find.text('WEDNESDAY'), findsOneWidget);
    expect(find.text('Join whole section'), findsOneWidget);

    // A retake student keeps CSE311 and CSE313 only.
    await scrollAndTap(tester, find.byType(Checkbox).last); // MAT201
    await tester.pumpAndSettle();
    expect(find.text('Add 2 courses'), findsOneWidget);
    expect(find.text('Join whole section'), findsOneWidget);
    await tester.tap(find.text('Add 2 courses'));
    await tester.pumpAndSettle();

    expect(classes.joinedCourses, {'CSE311', 'CSE313'});
    expect(classes.mine.single.hiddenCourses, {'MAT201'});
    expect(find.text('Added to your routine'), findsOneWidget);
    expect(find.text('Invite classmates'), findsOneWidget, reason: 'group');
  });

  testWidgets('find your class: a whole section, and offline', (tester) async {
    final classes = await signedIn(tester, others: {'ABCDEF': sampleGroup()});
    await tester.tap(find.text('Find your class'));
    await tester.pumpAndSettle();

    // Offline: says so, and tries again.
    classes.failure = const NetworkFailure();
    await search(tester, 'cse');
    expect(find.text('Searching needs an internet connection.'), findsOne);
    classes.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join whole section'));
    await tester.pumpAndSettle();
    expect(classes.joinedCourses, {'CSE311', 'CSE313', 'MAT201'});
    expect(classes.mine.single.hiddenCourses, isEmpty);
  });

  testWidgets('creating a group that may exist offers to join it', (
    tester,
  ) async {
    await signedIn(tester, others: {'ABCDEF': sampleGroup()});
    await tester.tap(find.text("I'm the CR, create a group"));
    await tester.pumpAndSettle();

    // Department and batch come from the profile: CSE 61 · A exists.
    expect(find.text('This class may already exist'), findsOneWidget);
    expect(find.text('CSE 61 · A'), findsOneWidget);

    // Another section: no warning.
    await tester.enterText(find.widgetWithText(TextField, 'Section'), 'b');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('This class may already exist'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'b'), 'a');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Join instead'));
    await tester.pumpAndSettle();
    expect(find.text('Join whole section'), findsOneWidget);
  });

  testWidgets('a CR makes the group code only', (tester) async {
    final classes = await signedIn(
      tester,
      mine: [sampleGroup(role: GroupRole.cr)],
    );
    await tester.tap(find.text('Routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Class groups'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Find your class'), findsOneWidget);
    await tester.tap(find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CsIcons.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit group details'));
    await tester.pumpAndSettle();

    // Findable by default; switched off, only the code lets people in.
    final findable = find.widgetWithText(SwitchListTile, 'Findable at DU');
    expect(tester.widget<SwitchListTile>(findable).value, isTrue);
    await scrollAndTap(tester, findable);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    expect(classes.lastUpdate?.discoverable, isFalse);
    expect(classes.mine.single.discoverable, isFalse);
  });
}
