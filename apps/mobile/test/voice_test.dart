import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
import 'package:campussaga/features/push/push_messaging.dart';
import 'package:campussaga/features/voice/data/voice_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'voice_fakes.dart';

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 12));
  tearDown(() => appNow = DateTime.now);

  late FakeVoiceRepository voice;
  late MemoryVoiceCache cache;
  late FakePhotoPicker photos;

  Future<void> start(
    WidgetTester tester, {
    bool flag = true,
    UserProfile user = testUser,
    Locale? locale,
    PushMessaging? push,
  }) async {
    usePhoneScreen(tester);
    final config = FakeAppConfigRepository()
      ..config = AppConfig(
        minSupportedBuild: 1,
        features: {'myClass': true, 'campusVoice': flag},
      );
    final (auth, _) = await registerFakes(
      config: config,
      voice: voice,
      voiceCache: cache,
      photos: photos,
      push: push,
      settings: MemorySettingsStorage(
        SettingsState(onboardingDone: true, locale: locale),
      ),
    );
    auth.savedUser = user;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  Future<void> openCampus(WidgetTester tester) async {
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    voice = FakeVoiceRepository()
      ..issues.addAll([
        sampleIssue(meToo: 12),
        sampleIssue(
          id: 'i2',
          title: 'Bus 4 always late in the morning',
          category: IssueCategory.transport,
          status: IssueStatus.inProgress,
        ),
      ]);
    cache = MemoryVoiceCache();
    photos = FakePhotoPicker();
  });

  testWidgets('the Campus tab follows the campusVoice flag', (tester) async {
    await start(tester, flag: false);
    expect(find.text('Campus'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // a fresh app
    await start(tester);
    await openCampus(tester);
    expect(find.text('Campus Voice'), findsOneWidget);
    expect(find.text('No water in Hall 2 since Sunday'), findsOneWidget);
    expect(find.text('Bus 4 always late in the morning'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    // Anonymous posts say so; never anything about the author.
    expect(find.text('Anonymous'), findsNWidgets(2));
  });

  testWidgets('filters by category and order, and keeps the feed offline', (
    tester,
  ) async {
    await start(tester);
    await openCampus(tester);
    final chips = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Transport'),
      150,
      scrollable: chips,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transport'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.category, IssueCategory.transport);
    expect(find.text('No water in Hall 2 since Sunday'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'All'),
      -150,
      scrollable: chips,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.sort, IssueSort.newest);
    expect(cache.feeds['u1/new'], hasLength(2), reason: 'saved for offline');

    voice.failure = const NetworkFailure();
    await tester.fling(
      find.text('No water in Hall 2 since Sunday'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('No water in Hall 2 since Sunday'), findsOneWidget);
  });

  testWidgets('raise an issue: category, details, photo, review, post', (
    tester,
  ) async {
    voice.similarResult = [
      sampleIssue(id: 'i9', title: 'Water problem in Hall 2').card,
    ];
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('Raise issue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNull,
      reason: 'nothing picked yet',
    );
    await tester.tap(find.text('Hostel'));
    await tester.pumpAndSettle();
    expect(
      find.text('Step 1 of 3'),
      findsOneWidget,
      reason: 'picking is not moving on',
    );
    expect(find.byIcon(CsIcons.checkCircle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);

    // Too short: say how much to write.
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Water');
    await tester.enterText(
      find.widgetWithText(TextField, 'Details'),
      'No water on the 3rd floor of Hall 2 since Sunday.',
    );
    await scrollAndTap(tester, find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Write at least 8 characters.'), findsOneWidget);
    expect(
      cache.savedDraft?.body,
      startsWith('No water'),
      reason: 'draft kept',
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'No water in Hall 2',
    );
    await scrollAndTap(tester, find.bySemanticsLabel('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(voice.uploads, hasLength(1));
    await scrollAndTap(tester, find.text('Next'));
    await tester.pumpAndSettle();

    // Review: similar issues, anonymous by default.
    expect(find.text('Before you post'), findsOneWidget);
    expect(find.text('Water problem in Hall 2'), findsOneWidget);
    expect(find.text('Post anonymously'), findsOneWidget);
    expect(
      find.text('Your name, email and class are never shown.'),
      findsOneWidget,
    );
    await scrollAndTap(tester, find.text('Post'));
    await tester.pumpAndSettle();

    final posted = voice.created.single;
    expect(posted.anonymous, isTrue);
    expect(posted.category, IssueCategory.hostel);
    expect(posted.imageIds, ['up1']);
    expect(cache.savedDraft, isNull, reason: 'draft cleared once posted');
    // The new issue opens.
    expect(find.text('No water in Hall 2'), findsWidgets);
    expect(find.text('You · 4 h ago'), findsOneWidget);
  });

  testWidgets('a held post explains itself to its author', (tester) async {
    voice.holdNext = true;
    voice.issues.add(
      sampleIssue(
        id: 'mine',
        title: 'Call 01712345678 about the canteen',
        mine: true,
        visibility: ContentVisibility.held,
        holdReason: 'personal_info',
      ),
    );
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.byTooltip('My issues'));
    await tester.pumpAndSettle();
    expect(find.text('Under review'), findsOneWidget);
    await tester.tap(find.text('Call 01712345678 about the canteen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Only you can see this while it\'s checked.'),
      findsOneWidget,
    );
    expect(find.textContaining('phone number, email'), findsOneWidget);
  });

  testWidgets('me too shows at once and rolls back when refused', (
    tester,
  ) async {
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('No water in Hall 2 since Sunday'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    await tester.tap(find.text('Me too'));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);

    voice.voteFailure = const RejectedFailure(code: 'VOICE_BANNED');
    await tester.tap(find.text('Me too'));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget, reason: 'rolled back');
    expect(
      find.text(
        "You can't post, comment or vote right now because of a rules break.",
      ),
      findsOneWidget,
    );
    // Back in the feed, the count followed.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('comments show handles, the author and officials; report', (
    tester,
  ) async {
    voice.commentsByIssue['i1'] = [
      IssueComment(
        id: 'c1',
        body: 'Same in Hall 3',
        handle: 'B2XZ',
        createdAt: DateTime(2026, 10, 27, 9),
      ),
      IssueComment(
        id: 'c2',
        body: 'Still nothing today',
        isIssueAuthor: true,
        createdAt: DateTime(2026, 10, 27, 10),
      ),
    ];
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('No water in Hall 2 since Sunday'));
    await tester.pumpAndSettle();
    expect(find.text('Student B2XZ'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Commenting as Anonymous'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Add a comment'),
      'Me too, room 304',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(voice.commentsByIssue['i1']!.last.body, 'Me too, room 304');
    await tester.dragUntilVisible(
      find.text('Student 7KQF'),
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    expect(find.text('Student 7KQF'), findsOneWidget);
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 3000),
      3000,
    );
    await tester.pumpAndSettle();

    // Report the issue: anonymous, with a reason.
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    expect(find.text('Reports are anonymous.'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Report'));
    await tester.pumpAndSettle();
    expect(voice.reports.single, ('i1', null, ReportReason.spam));
    expect(find.text('Thanks. Moderators will look at it.'), findsOneWidget);
  });

  testWidgets('officials change the status (a reason to reject) and reply', (
    tester,
  ) async {
    voice.issues
      ..clear()
      ..add(
        sampleIssue(
          can: const IssueCan(changeStatus: true, officialReply: true),
        ),
      );
    await start(
      tester,
      user: const UserProfile(
        id: 'u9',
        email: 'proctor@demo.ac.bd',
        university: University(id: 'uni1', slug: 'demo', name: 'Demo'),
        role: 'authority',
        displayName: 'Dr. Karim',
        department: 'Proctor Office',
        batch: '-',
        verified: true,
      ),
    );
    await openCampus(tester);
    expect(find.text('Safety reports'), findsOneWidget, reason: 'staff only');
    await tester.tap(find.text('No water in Hall 2 since Sunday'));
    await tester.pumpAndSettle();
    expect(find.text('University official'), findsOneWidget);

    await scrollAndTap(tester, find.text('Change status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejected'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Change status').last);
    await tester.pumpAndSettle();
    expect(find.text("Say why it's rejected."), findsOneWidget);
    await tester.tap(find.text('In progress'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Note for students'),
      'Pump ordered',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Change status').last);
    await tester.pumpAndSettle();
    expect(voice.statusChanges.single, (
      'i1',
      IssueStatus.inProgress,
      'Pump ordered',
    ));
    expect(find.text('Pump ordered'), findsOneWidget);
    expect(find.textContaining('Hall Provost'), findsWidgets);

    await scrollAndTap(tester, find.text('Official reply'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Water back by Thursday.',
    );
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Water back by Thursday.'),
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    expect(find.text('Dr. Karim'), findsOneWidget);
  });

  testWidgets('students see no official actions', (tester) async {
    await start(tester);
    await openCampus(tester);
    expect(find.text('Safety reports'), findsNothing);
    await tester.tap(find.text('No water in Hall 2 since Sunday'));
    await tester.pumpAndSettle();
    expect(find.text('Change status'), findsNothing);
    expect(find.text('Official reply'), findsNothing);
  });

  testWidgets('Bangla: tab, statuses and handles', (tester) async {
    voice.commentsByIssue['i1'] = [
      IssueComment(
        id: 'c1',
        body: 'আমারও',
        handle: 'B2XZ',
        createdAt: DateTime(2026, 10, 27, 9),
      ),
    ];
    await start(tester, locale: const Locale('bn'));
    await tester.tap(find.text('ক্যাম্পাস'));
    await tester.pumpAndSettle();
    expect(find.text('ক্যাম্পাস ভয়েস'), findsOneWidget);
    expect(find.text('কাজ চলছে'), findsOneWidget);
    expect(find.text('১২'), findsOneWidget, reason: 'Bangla digits');
    await tester.tap(find.text('No water in Hall 2 since Sunday'));
    await tester.pumpAndSettle();
    expect(find.text('শিক্ষার্থী B2XZ'), findsOneWidget);
  });

  testWidgets('a tapped issue push opens the issue', (tester) async {
    final push = MemoryPushMessaging();
    await start(tester, push: push);
    push.openedNotes.add(
      const PushNote(
        title: 'Issue update: In progress',
        data: {'type': 'issue_status', 'issueId': 'i2'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bus 4 always late in the morning'), findsOneWidget);
    expect(find.text('Comments · 0'.toUpperCase()), findsOneWidget);
  });

  testWidgets('how anonymity works', (tester) async {
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.byTooltip('How anonymity works'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your handle (like “Student 7KQF”) is different on every issue.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a saved draft reopens at step 1 with its category picked', (
    tester,
  ) async {
    cache
      ..draftUser = testUser.id
      ..savedDraft = const VoiceDraft(
        category: IssueCategory.hostel,
        body: 'No water on the 3rd floor',
      );
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('Raise issue'));
    await tester.pumpAndSettle();
    expect(
      find.text('Step 1 of 3'),
      findsOneWidget,
      reason: 'never jumps ahead',
    );
    expect(find.byIcon(CsIcons.checkCircle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('No water on the 3rd floor'), findsOneWidget);
  });

  testWidgets('a category picked but nothing typed is not restored', (
    tester,
  ) async {
    cache
      ..draftUser = testUser.id
      ..savedDraft = const VoiceDraft(category: IssueCategory.hostel);
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('Raise issue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byIcon(CsIcons.checkCircle), findsNothing);
  });
}
