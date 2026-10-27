import 'package:bloc_test/bloc_test.dart';
import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/features/classes/data/routine_cache.dart';
import 'package:campussaga/features/classes/presentation/bloc/my_classes_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 08:05: CSE311 starts at 08:30.
final tuesdayMorning = DateTime(2026, 10, 27, 8, 5);

Future<FakeClassGroupRepository> signedIn(
  WidgetTester tester, {
  List<ClassGroup> mine = const [],
  Map<String, ClassGroup> others = const {},
  RoutineCache? cache,
  Failure? failure,
}) async {
  usePhoneScreen(tester);
  final classes = FakeClassGroupRepository()
    ..mine.addAll(mine)
    ..others.addAll(others)
    ..failure = failure;
  final (repo, _) = await registerFakes(classes: classes, routineCache: cache);
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return classes;
}

void main() {
  setUp(() => appNow = () => tuesdayMorning);
  tearDown(() => appNow = DateTime.now);

  testWidgets('Today: next class with a countdown, then the rest of today', (
    tester,
  ) async {
    await signedIn(tester, mine: [sampleGroup()]);

    expect(find.text('Next class'), findsOneWidget);
    expect(find.text('in 25 min'), findsOneWidget);
    expect(find.text('CSE311'), findsNWidgets(2), reason: 'hero + list');
    expect(find.text("TODAY'S CLASSES"), findsOneWidget);
    expect(find.text('CSE313'), findsOneWidget);
    expect(find.text('MAT201'), findsNothing, reason: 'that is Wednesday');

    // During the class: "Now", and when it ends.
    appNow = () => DateTime(2026, 10, 27, 9, 0);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Now'), findsWidgets);
    expect(find.text('ends in 60 min'), findsOneWidget);

    // After the last class: done, and when the next one is.
    appNow = () => DateTime(2026, 10, 27, 14, 0);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('Next class: Wednesday'), findsOneWidget);
    expect(find.text('MAT201'), findsOneWidget);
  });

  testWidgets('Today: a CR reaches the routine from any class or the group', (
    tester,
  ) async {
    appNow = () => DateTime(2026, 10, 27, 14, 0); // done for today
    await signedIn(tester, mine: [sampleGroup(role: GroupRole.cr)]);
    expect(find.text('CLASS GROUPS'), findsOneWidget);
    expect(find.text('CR'), findsOneWidget);

    // The "next class" card opens the class; from there, the group.
    await scrollAndTap(tester, find.text('MAT201'));
    await tester.pumpAndSettle();
    expect(find.text('Edit weekly class'), findsOneWidget);
    await tester.tap(find.text('Open class group'));
    await tester.pumpAndSettle();
    expect(find.text('Invite classmates'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    expect(find.text('Invite classmates'), findsOneWidget);
  });

  testWidgets('a classmate joins with the code', (tester) async {
    final classes = await signedIn(tester, others: {'ABCDEF': sampleGroup()});
    expect(find.text('No classes yet'), findsOneWidget);

    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    expect(find.text('Join your class group'), findsOneWidget);

    // A wrong code says why.
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No class group with this code'), findsOne);

    // The right one (typed in lower case) shows the group first.
    await tester.enterText(find.byType(TextField), 'abcdef');
    await tester.pumpAndSettle();
    expect(find.text('CSE 61 · A'), findsOneWidget);
    expect(find.text('41 students'), findsOneWidget);
    expect(find.text('3 classes a week'), findsOneWidget);

    await scrollAndTap(tester, find.text('Join group'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.id, 'g-cse');
    expect(find.text('Invite classmates'), findsOneWidget);
    expect(find.text('TUESDAY'), findsOneWidget);
    expect(find.text('Add class'), findsNothing, reason: 'members only read');

    // Back home, today's classes are there.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('in 25 min'), findsOneWidget);
  });

  testWidgets('a CR creates a group and enters the routine', (tester) async {
    final classes = await signedIn(tester);

    await tester.tap(find.text("I'm the CR, create a group"));
    await tester.pumpAndSettle();
    // Department and batch come from the profile; semester is suggested.
    expect(find.widgetWithText(TextField, 'CSE'), findsOneWidget);
    expect(find.widgetWithText(TextField, '61'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Fall 2026'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Section'), 'b');
    await scrollAndTap(tester, find.text('Create group'));
    await tester.pumpAndSettle();

    expect(find.text('CSE 61 · b'), findsOneWidget);
    expect(find.text('KQWZRT'), findsOneWidget);

    // Copying the invite puts a ready message on the clipboard.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.tap(find.byTooltip('Copy invite'));
    await tester.pump();
    expect(copied, contains('KQWZRT'));
    expect(copied, contains('CSE 61 · b'));

    // First class.
    await scrollAndTap(tester, find.text('Add class'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Course code'),
      'CSE311',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Course title'),
      'Database Systems',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Room'), '504');
    // No day picked yet: caught before saving.
    await scrollAndTap(tester, find.text('Save and add another'));
    await tester.pumpAndSettle();
    expect(find.text('Pick at least one day.'), findsOneWidget);
    expect(classes.mine.single.slots, isEmpty);

    // The same class on Saturday and Tuesday: one save, one entry per day.
    await scrollAndTap(tester, find.text('Sat'));
    await scrollAndTap(tester, find.text('Tue'));
    await scrollAndTap(tester, find.text('Save and add another'));
    await tester.pumpAndSettle();
    expect(find.text('2 classes added'), findsOneWidget);
    expect(classes.mine.single.slots.map((s) => (s.courseCode, s.weekday)), [
      ('CSE311', DateTime.saturday),
      ('CSE311', DateTime.tuesday),
    ]);

    // The next one starts when the first ends; the course is suggested.
    await tester.enterText(
      find.widgetWithText(TextField, 'Course code'),
      'cse3',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Database Systems').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '504'), findsOneWidget);
    // The days stay picked; this one is only on Wednesday.
    await scrollAndTap(tester, find.text('Sat'));
    await scrollAndTap(tester, find.text('Tue'));
    await scrollAndTap(tester, find.text('Wed'));
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();

    final slots = classes.mine.single.slots;
    expect(slots, hasLength(3));
    expect(slots[2].weekday, DateTime.wednesday);
    expect(slots[2].startMin, 10 * 60, reason: 'starts when the last ended');
    expect(slots[2].endMin, 11 * 60 + 30);
    expect(find.text('SATURDAY'), findsOneWidget);
    expect(find.text('WEDNESDAY'), findsOneWidget);

    // A missing course code is caught before saving.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('This is required.'), findsOneWidget);
    expect(classes.mine.single.slots, hasLength(3));
  });

  testWidgets('the CR edits and deletes a class', (tester) async {
    final classes = await signedIn(
      tester,
      mine: [sampleGroup(role: GroupRole.cr)],
    );
    await scrollAndTap(tester, find.text('CSE313'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open class group'));
    await tester.pumpAndSettle();
    expect(find.text('Invite classmates'), findsOneWidget);

    await scrollAndTap(tester, find.text('CSE313'));
    await tester.pumpAndSettle();
    expect(find.text('Edit class'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '602'), '701');
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.slots[1].room, '701');

    await scrollAndTap(tester, find.text('CSE313'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Delete class'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this class for everyone?'), findsOneWidget);
    await tester.tap(find.text('Delete class').last);
    await tester.pumpAndSettle();
    expect(classes.mine.single.slots.map((s) => s.courseCode), [
      'CSE311',
      'MAT201',
    ]);

    // Editing: pick another day to put the class there too.
    await scrollAndTap(tester, find.text('MAT201'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Thu'));
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      classes.mine.single.slots
          .where((s) => s.courseCode == 'MAT201')
          .map((s) => s.weekday),
      [DateTime.wednesday, DateTime.thursday],
    );

    // Unpicking its own day moves the class.
    await scrollAndTap(tester, find.text('CSE311'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Tue'));
    await scrollAndTap(tester, find.text('Sun'));
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();
    final cse311 = classes.mine.single.slots.where(
      (s) => s.courseCode == 'CSE311',
    );
    expect(cse311.single.weekday, DateTime.sunday);
    expect(cse311.single.id, 's-311', reason: 'the same class, moved');
  });

  testWidgets('Routine shows each day; leaving a group removes it', (
    tester,
  ) async {
    final classes = await signedIn(tester, mine: [sampleGroup()]);
    await tester.tap(find.text('Routine'));
    await tester.pumpAndSettle();
    expect(find.text('CSE311'), findsOneWidget);

    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();
    expect(find.text('MAT201'), findsOneWidget);
    await tester.tap(find.text('30'));
    await tester.pumpAndSettle();
    expect(find.text('No classes on this day'), findsOneWidget);

    await tester.tap(find.byTooltip('Class groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave group').last);
    await tester.pumpAndSettle();
    expect(classes.mine, isEmpty);
    expect(find.text('CSE 61 · A'), findsNothing);
  });

  testWidgets('offline: the saved routine still shows', (tester) async {
    final cache = MemoryRoutineCache()
      ..userId = testUser.id
      ..groups = [sampleGroup()];
    await signedIn(tester, cache: cache, failure: const NetworkFailure());

    expect(find.text('in 25 min'), findsOneWidget);
    expect(find.text('Offline. Showing your saved routine.'), findsOneWidget);
  });

  group('MyClassesCubit', () {
    blocTest<MyClassesCubit, MyClassesState>(
      'shows the saved routine first, then the server one',
      build: () {
        final repo = FakeClassGroupRepository()..mine.add(sampleGroup());
        final cache = MemoryRoutineCache()
          ..userId = 'u1'
          ..groups = const [];
        return MyClassesCubit(repo, cache);
      },
      act: (c) => c.start('u1'),
      verify: (c) {
        expect(c.state.loaded, isTrue);
        expect(c.state.groups.single.id, 'g-cse');
      },
    );

    test("another student never sees someone else's saved routine", () async {
      final cache = MemoryRoutineCache();
      await cache.write('u1', (groups: [sampleGroup()], personal: const []));
      expect(await cache.read('u2'), isNull);

      final cubit = MyClassesCubit(FakeClassGroupRepository(), cache);
      await cubit.start('u1');
      await cubit.clear();
      expect(cubit.state.groups, isEmpty);
      expect(await cache.read('u1'), isNull, reason: 'cleared on sign-out');
      await cubit.close();
    });
  });
}
