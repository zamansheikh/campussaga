import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/di.dart';
import 'package:campussaga/features/cgpa/data/cgpa_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late MemoryCgpaStore store;

  Future<void> start(WidgetTester tester) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes(
      classes: FakeClassGroupRepository()..mine.add(sampleGroup()),
    );
    store = MemoryCgpaStore();
    getIt.registerSingleton<CgpaStore>(store);
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CGPA calculator'));
    await tester.pumpAndSettle();
  }

  testWidgets('add a semester and a course: the CGPA shows and is saved', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Track your CGPA'), findsOneWidget);

    await tester.tap(find.text('Add semester'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Spring 2026');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The new semester opens; the routine's courses are offered.
    expect(find.text('Spring 2026'), findsOneWidget);
    expect(find.text("Add my routine's courses"), findsOneWidget);

    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Course code'),
      'cse101',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'A+'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('CSE101'), findsOneWidget);

    // A second course by marks: 72 → A- (3.50).
    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Course code'),
      'MAT101',
    );
    await tester.tap(find.text('Marks'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Marks out of 100'),
      '72',
    );
    await tester.pumpAndSettle();
    expect(find.text('Grade: A- (3.50)'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    // (3 × 4.00 + 3 × 3.50) / 6 = 3.75
    expect(find.text('3.75'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text('3.75'),
      findsNWidgets(2),
      reason: 'CGPA and last semester on the summary',
    );
    expect(find.text('GPA 3.75 · 6 credits'), findsOneWidget);

    // Saved on the phone, per user.
    final saved = CgpaBook.fromJson(
      jsonDecode(store.saved[testUser.id]!) as Map<String, Object?>,
    );
    expect(saved.semesters.single.courses, hasLength(2));
    expect(saved.cgpa.gpa, 3.75);
  });

  testWidgets('courses from the routine; a wrong course is caught', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Add semester'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fall 2026');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Add my routine's courses"));
    await tester.pumpAndSettle();
    expect(find.text('CSE311'), findsOneWidget);
    expect(find.text('MAT201'), findsOneWidget);
    expect(find.text("Add my routine's courses"), findsNothing);

    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Credits'), '9');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a course code or title.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Course code'), 'X1');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Credits must be between 0.5 and 6.'), findsOneWidget);
  });

  testWidgets('a saved record comes back; target planner', (tester) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes();
    store = MemoryCgpaStore();
    await store.write(
      testUser.id,
      const CgpaBook(
        semesters: [
          Semester(
            id: 's1',
            name: 'Spring 2026',
            courses: [
              CgpaCourse(id: 'c1', code: 'CSE101', credits: 30, letter: 'B'),
            ],
          ),
        ],
      ),
    );
    getIt.registerSingleton<CgpaStore>(store);
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CGPA calculator'));
    await tester.pumpAndSettle();
    expect(find.text('3.00'), findsWidgets);

    await tester.tap(find.text('Plan a target'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Target CGPA'),
      '3.25',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Credits left to take'),
      '15',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You need a GPA of 3.75 in those credits.'),
      findsOneWidget,
    );
  });
}
