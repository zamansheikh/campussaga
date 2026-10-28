import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/features/announcements/data/seen_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 08:05.
final tuesdayMorning = DateTime(2026, 10, 27, 8, 5);

Announcement note(String id, String body, DateTime at, {bool pinned = false}) =>
    Announcement(id: id, body: body, createdAt: at, pinned: pinned);

Future<FakeClassGroupRepository> signedIn(
  WidgetTester tester,
  ClassGroup group, {
  SeenStore? seen,
}) async {
  usePhoneScreen(tester);
  final classes = FakeClassGroupRepository()..mine.add(group);
  final (repo, _) = await registerFakes(classes: classes, seenStore: seen);
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return classes;
}

void main() {
  setUp(() => appNow = () => tuesdayMorning);
  tearDown(() => appNow = DateTime.now);

  testWidgets('the CR posts a pinned announcement', (tester) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    await scrollAndTap(tester, find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Post updates for your class here'), findsOne);

    await scrollAndTap(tester, find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('New announcement'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Bring a calculator tomorrow',
    );
    await tester.tap(find.text('Pin to top'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    final a = classes.mine.single.announcements.single;
    expect(a.body, 'Bring a calculator tomorrow');
    expect(a.pinned, isTrue);
    expect(find.textContaining('Posted.'), findsOneWidget);
    expect(find.text('Bring a calculator tomorrow'), findsOneWidget);
    expect(find.text('Pinned'), findsOneWidget);

    // Unpin, then delete (asks first).
    final cardMenu = find.descendant(
      of: find.byType(Card),
      matching: find.byIcon(CsIcons.more),
    );
    await tester.tap(cardMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpin'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.announcements.single.pinned, isFalse);

    await tester.tap(cardMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this announcement for everyone?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(classes.mine.single.announcements, isEmpty);
  });

  testWidgets('classmates see new announcements on Today until they look', (
    tester,
  ) async {
    final seen = MemorySeenStore();
    final g = sampleGroup().copyWith(
      announcements: [
        note(
          'a1',
          'Class rules: phones silent',
          DateTime(2026, 9, 1),
          pinned: true,
        ),
        note('a2', 'Quiz on Sunday, chapters 3-4', DateTime(2026, 10, 26, 20)),
        note('a3', 'Old news', DateTime(2026, 10, 20)),
      ],
    );
    await signedIn(tester, g, seen: seen);

    expect(find.text('ANNOUNCEMENTS'), findsOneWidget);
    expect(find.text('Quiz on Sunday, chapters 3-4'), findsOneWidget);
    expect(find.text('Class rules: phones silent'), findsOneWidget);
    expect(find.text('Old news'), findsNothing, reason: 'older than 3 days');
    expect(find.text('New'), findsNWidgets(2));
    expect(find.textContaining('yesterday'), findsOneWidget);

    // Members have no menu on the group page; opening it marks all seen.
    await scrollAndTap(tester, find.text('Quiz on Sunday, chapters 3-4'));
    await tester.pumpAndSettle();
    expect(find.text('Old news'), findsOneWidget);
    expect(find.byIcon(CsIcons.more), findsOneWidget, reason: 'app bar only');
    expect(find.text('Post'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('New'), findsNothing);
    expect(seen.saved['g-cse'], DateTime(2026, 10, 26, 20));
  });
}
