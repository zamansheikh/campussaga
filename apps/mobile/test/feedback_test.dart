import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';

import 'campus_fakes.dart';
import 'helpers/fakes.dart';

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 12));
  tearDown(() => appNow = DateTime.now);

  late FakeFeedbackRepository feedback;

  setUp(() => feedback = FakeFeedbackRepository());

  Future<void> openHelp(WidgetTester tester) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes(feedback: feedback);
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Help & feedback'));
    await tester.pumpAndSettle();
  }

  testWidgets('send feedback: checks the message, attaches a screenshot', (
    tester,
  ) async {
    await openHelp(tester);
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();

    // What is attached is shown quietly.
    expect(
      find.text(
        'Sent with it: VarsityKotha 0.1.0 (1) · Google Pixel 7 · Android 14 · en',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Idea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'too short');
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(find.text('Write at least 10 characters.'), findsOneWidget);
    expect(feedback.sent, isEmpty);

    await tester.tap(find.byTooltip('Add screenshot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(feedback.uploads, hasLength(1));

    await tester.enterText(
      find.byType(TextField),
      'Please add a dark mode for the routine',
    );
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    final sent = feedback.sent.single;
    expect(sent.kind, FeedbackKind.idea);
    expect(sent.message, 'Please add a dark mode for the routine');
    expect(sent.imageIds, ['up1']);
    expect(sent.appVersion, '0.1.0');
    expect(sent.build, 1);
    expect(sent.device, 'Google Pixel 7');
    expect(sent.os, 'Android 14');
    expect(sent.locale, 'en');
    expect(find.text('Thanks! We got your feedback.'), findsOneWidget);
    expect(find.text('Help & feedback'), findsWidgets, reason: 'back');
  });

  testWidgets('the daily limit is explained', (tester) async {
    feedback.failure = const RateLimitedFailure(code: 'FEEDBACK_LIMIT');
    await openHelp(tester);
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Something is broken here');
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(
      find.text("You've sent 10 today. Please try again tomorrow."),
      findsOneWidget,
    );
  });

  testWidgets('my feedback: empty, then statuses and the unread dot', (
    tester,
  ) async {
    await openHelp(tester);
    await tester.tap(find.text('My feedback'));
    await tester.pumpAndSettle();
    expect(find.text("You haven't sent any feedback yet"), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    feedback.entries = [
      FeedbackEntry(
        id: 'f1',
        kind: FeedbackKind.bug,
        message: 'Routine crashes on Friday',
        status: FeedbackStatus.planned,
        createdAt: DateTime(2026, 10, 25),
        lastMessageAt: DateTime(2026, 10, 27, 9),
        unread: true,
      ),
      FeedbackEntry(
        id: 'f2',
        kind: FeedbackKind.idea,
        message: 'Add a widget',
        status: FeedbackStatus.done,
        createdAt: DateTime(2026, 10, 20),
        lastMessageAt: DateTime(2026, 10, 21),
      ),
    ];
    await tester.tap(find.text('My feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);
  });

  testWidgets('a thread: the team replied, the student answers', (
    tester,
  ) async {
    feedback.entries = [
      FeedbackEntry(
        id: 'f1',
        kind: FeedbackKind.bug,
        message: 'Routine crashes on Friday',
        status: FeedbackStatus.fresh,
        createdAt: DateTime(2026, 10, 25),
        lastMessageAt: DateTime(2026, 10, 25),
      ),
    ];
    feedback.addTeamReply('f1', 'Thanks, which phone do you use?');
    await openHelp(tester);
    await tester.tap(find.text('My feedback'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);

    await tester.tap(find.text('Routine crashes on Friday'));
    await tester.pumpAndSettle();
    expect(find.text('Routine crashes on Friday'), findsOneWidget);
    expect(find.text('Thanks, which phone do you use?'), findsOneWidget);
    expect(find.textContaining('VarsityKotha team'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'A Redmi Note 12');
    await tester.tap(find.byTooltip('Send reply'));
    await tester.pumpAndSettle();
    expect(feedback.replies.single, ('f1', 'A Redmi Note 12'));
    expect(find.text('A Redmi Note 12'), findsOneWidget);

    // Opening the thread cleared the unread mark.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
  });

  testWidgets('a missing thread is explained', (tester) async {
    await openHelp(tester);
    feedback.entries = [
      FeedbackEntry(
        id: 'f9',
        kind: FeedbackKind.other,
        message: 'Hello there team',
        status: FeedbackStatus.seen,
      ),
    ];
    await tester.tap(find.text('My feedback'));
    await tester.pumpAndSettle();
    feedback.entries = [];
    await tester.tap(find.text('Hello there team'));
    await tester.pumpAndSettle();
    expect(find.text("This feedback isn't available."), findsOneWidget);
  });
}
