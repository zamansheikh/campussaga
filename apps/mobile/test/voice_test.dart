import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/app/settings/bloc/settings_state.dart';
import 'package:varsitykotha/app/settings/settings_storage.dart';
import 'package:varsitykotha/features/push/push_messaging.dart';
import 'package:varsitykotha/features/voice/data/voice_cache.dart';

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
    expect(find.text("What's happening on campus?"), findsOneWidget);
    expect(find.text('For you'), findsOneWidget);
    expect(find.text('No water in Hall 2 since Sunday'), findsOneWidget);
    expect(find.text('Bus 4 always late in the morning'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    // Anonymous posts say so; never anything about the author.
    expect(find.text('Anonymous'), findsNWidgets(2));
    // Every post has the same three actions.
    expect(find.text('Me too'), findsNWidgets(2));
    expect(find.text('Share'), findsNWidgets(2));
    expect(voice.feedCalls.last.kinds, isNull, reason: 'every kind');
  });

  testWidgets('tabs, topics and the offline copy', (tester) async {
    await start(tester);
    await openCampus(tester);
    await tester.dragUntilVisible(
      find.widgetWithText(ChoiceChip, 'Transport'),
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      const Offset(-150, 0),
    );
    await scrollAndTap(tester, find.widgetWithText(ChoiceChip, 'Transport'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.category, IssueCategory.transport);
    expect(find.text('No water in Hall 2 since Sunday'), findsNothing);
    // Tapping it again shows everything.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transport'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.category, isNull);

    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.sort, IssueSort.newest);
    expect(cache.feeds['u1/latest'], hasLength(2), reason: 'saved offline');

    await tester.tap(find.text('Q&A'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.kinds, {PostKind.question});
    expect(find.text('No questions yet'), findsOneWidget);

    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.kinds, {PostKind.issue});
    expect(find.text('Safety reports'), findsNothing, reason: 'staff only');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Solved'));
    await tester.pumpAndSettle();
    expect(voice.feedCalls.last.sort, IssueSort.solved);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Open'));
    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();

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

  testWidgets('share a post with a photo, anonymously', (tester) async {
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();
    expect(find.text('Create post'), findsOneWidget);
    expect(find.text('Anonymous'), findsOneWidget, reason: 'the default');
    final post = find.widgetWithText(FilledButton, 'Post');
    expect(tester.widget<FilledButton>(post).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField).first,
      'Free coffee at the TSC fair today!',
    );
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.widgetWithText(ChoiceChip, 'Events'));
    await scrollAndTap(tester, find.bySemanticsLabel('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(voice.uploads, hasLength(1));
    expect(cache.savedDraft?.kind, PostKind.post, reason: 'draft kept');

    await tester.tap(post);
    await tester.pumpAndSettle();
    final d = voice.created.single;
    expect(d.kind, PostKind.post);
    expect(d.category, IssueCategory.event);
    expect(d.anonymous, isTrue);
    expect(d.imageIds, ['up1']);
    expect(d.toJson().containsKey('title'), isFalse);
    expect(cache.savedDraft, isNull, reason: 'draft cleared once posted');
    // The new post opens.
    expect(find.text('Free coffee at the TSC fair today!'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('make a poll from the feed', (tester) async {
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('Poll'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Best place for tea?');
    await tester.enterText(find.widgetWithText(TextField, 'Option 1'), 'TSC');
    await tester.enterText(find.widgetWithText(TextField, 'Option 2'), 'tsc');
    await tester.pumpAndSettle();
    expect(find.text('Add at least two different options.'), findsOneWidget);
    final post = find.widgetWithText(FilledButton, 'Post');
    expect(tester.widget<FilledButton>(post).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Option 2'),
      'Bot tola',
    );
    await scrollAndTap(tester, find.text('Add option'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Option 3'),
      'Hall canteen',
    );
    await scrollAndTap(tester, find.text('7 days'));
    await tester.pumpAndSettle();
    await tester.tap(post);
    await tester.pumpAndSettle();
    final d = voice.created.single;
    expect(d.kind, PostKind.poll);
    expect(d.pollOptions, ['TSC', 'Bot tola', 'Hall canteen']);
    expect(d.pollDays, 7);
    expect(d.category, IssueCategory.general);
  });

  testWidgets('raise an issue: category, title, similar issues, photo', (
    tester,
  ) async {
    voice.similarResult = [
      sampleIssue(id: 'i9', title: 'Water problem in Hall 2').card,
    ];
    await start(tester);
    await openCampus(tester);
    await tester.tap(find.text('Issue'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Issues go to your university's officials, who can reply and update "
        'the status.',
      ),
      findsOneWidget,
    );
    final post = find.widgetWithText(FilledButton, 'Post');
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Water');
    await tester.enterText(
      find.widgetWithText(TextField, 'Details'),
      'No water on the 3rd floor of Hall 2 since Sunday.',
    );
    await tester.pumpAndSettle();
    expect(find.text('Write at least 8 characters.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(post).onPressed,
      isNull,
      reason: 'no category, title too short',
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Hostel'));
    await scrollAndTap(tester, find.bySemanticsLabel('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'No water in Hall 2',
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Similar issues'));
    expect(find.text('Similar issues'), findsOneWidget);
    expect(find.text('Water problem in Hall 2'), findsOneWidget);

    await tester.tap(post);
    await tester.pumpAndSettle();
    final d = voice.created.single;
    expect(d.kind, PostKind.issue);
    expect(d.category, IssueCategory.hostel);
    expect(d.title, 'No water in Hall 2');
    expect(d.imageIds, ['up1']);
    expect(find.text('No water in Hall 2'), findsWidgets);
  });

  testWidgets('a held post explains itself to its author', (tester) async {
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
    await tester.tap(find.byTooltip('My posts'));
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

  testWidgets('react to a post: tap for a like, hold to pick', (tester) async {
    voice.issues
      ..clear()
      ..add(
        sampleIssue(
          id: 'p1',
          kind: PostKind.post,
          category: IssueCategory.fun,
          body: 'Who else is still awake for the 8 AM class?',
          meToo: 2,
          reactions: const {Reaction.haha: 2},
        ),
      );
    await start(tester);
    await openCampus(tester);
    expect(find.text('😂'), findsOneWidget, reason: 'the summary');
    await tester.tap(find.text('Like'));
    await tester.pumpAndSettle();
    expect(voice.issues.single.card.myReaction, Reaction.like);
    expect(find.text('3'), findsOneWidget);

    await tester.longPress(find.text('Like'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Wow'));
    await tester.pumpAndSettle();
    expect(voice.issues.single.card.myReaction, Reaction.wow);
    expect(find.text('Wow'), findsOneWidget, reason: 'the button says so');
    expect(find.text('3'), findsOneWidget, reason: 'still one each');

    await tester.tap(find.text('Wow'));
    await tester.pumpAndSettle();
    expect(voice.issues.single.card.myReaction, isNull);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('vote in a poll, then see the results', (tester) async {
    voice.issues
      ..clear()
      ..add(
        sampleIssue(
          id: 'p1',
          kind: PostKind.poll,
          category: IssueCategory.food,
          body: 'Best place for tea?',
          meToo: 0,
          poll: Poll(
            options: const [
              PollOption(id: 'o1', label: 'TSC'),
              PollOption(id: 'o2', label: 'Bot tola'),
            ],
            totalVotes: 2,
            closesAt: DateTime(2026, 10, 30),
          ),
        ),
      );
    await start(tester);
    await openCampus(tester);
    expect(
      find.text('2 votes · 3 days left · Vote to see the results'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bot tola'));
    await tester.pumpAndSettle();
    expect(voice.issues.single.card.poll!.myVote, 'o2');
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('3 votes · 3 days left'), findsOneWidget);
  });

  testWidgets('comments: handles, the author, replies and likes; report', (
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
    final list = find.byType(ListView).first;
    await tester.dragUntilVisible(
      find.text('Student B2XZ'),
      list,
      const Offset(0, -250),
    );
    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Commenting as Anonymous'), findsOneWidget);

    // Like, then reply to the first comment.
    await tester.tap(find.text('Like').first);
    await tester.pumpAndSettle();
    expect(voice.commentsByIssue['i1']!.first.liked, isTrue);
    expect(find.text('Like · 1'), findsOneWidget);
    await tester.tap(find.text('Reply').first);
    await tester.pumpAndSettle();
    expect(find.text('Replying to Student B2XZ'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Write a reply…'),
      'Room 304 too',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    final reply = voice.commentsByIssue['i1']!.last;
    expect(reply.body, 'Room 304 too');
    expect(reply.parentId, 'c1');
    expect(find.text('Commenting as Anonymous'), findsOneWidget);
    await tester.fling(list, const Offset(0, 3000), 3000);
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
    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    expect(find.text('Safety reports'), findsOneWidget, reason: 'staff');
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
    expect(find.text('ক্যাম্পাসে কী হচ্ছে?'), findsOneWidget);
    expect(find.text('কাজ চলছে'), findsOneWidget);
    expect(find.text('১২'), findsOneWidget, reason: 'Bangla digits');
    await tester.tap(find.text('No water in Hall 2 since Sunday'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('শিক্ষার্থী B2XZ'),
      find.byType(ListView).first,
      const Offset(0, -250),
    );
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
    await tester.dragUntilVisible(
      find.text('0 COMMENTS'),
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    expect(find.text('0 COMMENTS'), findsOneWidget);
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

  testWidgets('a saved issue draft comes back in the issue composer', (
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
    // Another kind starts empty.
    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();
    expect(find.text('No water on the 3rd floor'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Issue'));
    await tester.pumpAndSettle();
    expect(find.text('No water on the 3rd floor'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Hostel'))
          .selected,
      isTrue,
    );
  });
}
