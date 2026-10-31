import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/app/router.dart';
import 'package:varsitykotha/app/settings/bloc/settings_state.dart';
import 'package:varsitykotha/app/settings/settings_storage.dart';
import 'package:varsitykotha/features/classes/data/invite_link.dart';
import 'package:varsitykotha/features/growth/presentation/invite_share.dart';
import 'package:varsitykotha/features/growth/presentation/pages/student_profile_page.dart';
import 'package:varsitykotha/features/profile/presentation/widgets/user_avatar.dart';
import 'package:varsitykotha/features/push/push_messaging.dart';

import 'growth_fakes.dart';
import 'helpers/fakes.dart';
import 'voice_fakes.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appNow = () => now;
    PendingReferral.clear();
  });
  tearDown(() {
    appNow = DateTime.now;
    PendingReferral.clear();
  });

  late FakeGrowthRepository growth;
  late FakeProfileRepository profile;
  late FakeVoiceRepository voice;
  late FakeClassGroupRepository classes;
  late MemoryPushMessaging push;
  late List<String> shared;

  setUp(() {
    growth = FakeGrowthRepository();
    profile = FakeProfileRepository();
    voice = FakeVoiceRepository();
    classes = FakeClassGroupRepository();
    push = MemoryPushMessaging();
    shared = [];
    final original = inviteShare;
    inviteShare = (text, origin) async => shared.add(text);
    addTearDown(() => inviteShare = original);
  });

  Future<void> start(
    WidgetTester tester, {
    bool voiceFlag = true,
    Locale? locale,
  }) async {
    usePhoneScreen(tester);
    final config = FakeAppConfigRepository()
      ..config = AppConfig(
        minSupportedBuild: 1,
        features: {'myClass': true, 'campusVoice': voiceFlag},
      );
    final (auth, _) = await registerFakes(
      config: config,
      growth: growth,
      profile: profile,
      voice: voice,
      classes: classes,
      push: push,
      settings: MemorySettingsStorage(
        SettingsState(onboardingDone: true, locale: locale),
      ),
    );
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String route) async {
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push(route),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openProfileTab(WidgetTester tester) async {
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }

  group('invite card', () {
    testWidgets('shows the counts and the friends still pending, and shares', (
      tester,
    ) async {
      growth.stats = ReferralStats(
        code: 'abcd1234',
        link: 'https://varsitykotha.com/r/abcd1234',
        invited: 12,
        joined: 8,
        pending: [
          const PendingFriend(name: 'Rafi', verified: true, activeDays: 2),
          const PendingFriend(name: 'Mim', activeDays: 0),
        ],
        recent: ['Tania Islam', 'Sami Khan'],
      );
      growth.campaignList = [sampleCampaign(now: now)];
      await start(tester);
      await openProfileTab(tester);
      expect(find.text('INVITE FRIENDS'), findsOneWidget);
      expect(find.text('Invited 12 · 8 joined'), findsOneWidget);
      expect(find.text('TI'), findsOneWidget, reason: 'faces of who joined');
      expect(find.text('17 more friends for Silver Connector'), findsOneWidget);
      expect(
        find.text(
          "+10 points a friend · +5 extra points if they're at another university",
        ),
        findsOneWidget,
      );
      expect(find.text('Rafi · verified · 2 of 3 days'), findsOneWidget);
      expect(find.text('Mim · not verified yet · 0 of 3 days'), findsOneWidget);

      await scrollAndTap(tester, find.byTooltip('Your invite QR'));
      await tester.pumpAndSettle();
      expect(find.text('Your invite QR'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.tapAt(const Offset(20, 20)); // close the sheet
      await tester.pumpAndSettle();

      await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Share'));
      await tester.pumpAndSettle();
      expect(shared, hasLength(1));
      expect(shared.single, contains('https://varsitykotha.com/r/abcd1234'));
      expect(shared.single, contains('VarsityKotha'));
    });

    testWidgets('nothing shows when the server has no invites yet', (
      tester,
    ) async {
      growth.failure = const NetworkFailure();
      await start(tester);
      await openProfileTab(tester);
      expect(find.text('INVITE FRIENDS'), findsNothing);
      expect(find.text('BADGES'), findsNothing);
    });
  });

  group('badges', () {
    testWidgets('earned with tiers, private marked, locked say how to earn', (
      tester,
    ) async {
      growth.badges = sampleBadges();
      await start(tester);
      await openProfileTab(tester);
      expect(find.text('BADGES'), findsOneWidget);
      // Profile: one compact row of earned badges, and See all.
      expect(find.text('Connector'), findsOneWidget);
      expect(find.text('NOT EARNED YET'), findsNothing);
      await scrollAndTap(tester, find.textContaining('See all'));
      await tester.pumpAndSettle();
      // The Badges page: earned ones with the tier under the name.
      expect(find.text('Connector'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
      // Private: only the owner sees it.
      expect(find.text('Helper'), findsOneWidget);
      expect(find.text('Only you see this'), findsWidgets);
      // Locked: greyed, with how to earn it.
      expect(find.text('NOT EARNED YET'), findsOneWidget);
      expect(find.text('Bug hunter'), findsOneWidget);
      expect(find.textContaining('Send bug reports that we fix.'), findsOne);
      final locked = tester.widget<CsBadgeIcon>(
        find.byWidgetPredicate(
          (w) => w is CsBadgeIcon && w.badgeKey == 'bug_hunter',
        ),
      );
      expect(locked.locked, isTrue);
    });

    testWidgets('show a badge by my name; errors are in plain words', (
      tester,
    ) async {
      growth.badges = sampleBadges();
      await start(tester);
      await openProfileTab(tester);
      await scrollAndTap(tester, find.text('Connector'));
      await tester.pumpAndSettle();
      expect(find.text('Bronze 5 · Silver 25 · Gold 100'), findsOneWidget);

      growth.featureFailure = const RejectedFailure(code: 'BADGE_NOT_HELD');
      await tester.tap(find.text('Show by my name'));
      await tester.pumpAndSettle();
      expect(find.text("You don't have this badge (any more)."), findsOne);
      expect(
        find.text('Show by my name'),
        findsOneWidget,
        reason: 'still open',
      );

      growth.featureFailure = null;
      await tester.tap(find.text('Show by my name'));
      await tester.pumpAndSettle();
      expect(growth.featureCalls, ['connector', 'connector']);
      expect(find.text('Now shown by your name'), findsOneWidget);

      // It is the one shown now: the sheet offers to stop.
      await tester.pump(const Duration(seconds: 5));
      await scrollAndTap(tester, find.text('Connector'));
      await tester.pumpAndSettle();
      expect(find.text('Shown by your name'), findsOneWidget);
      await tester.tap(find.text('Stop showing'));
      await tester.pumpAndSettle();
      expect(growth.featureCalls.last, isNull);
      expect(find.text('No badge by your name now'), findsOneWidget);
    });

    testWidgets("a private badge can't be shown by my name", (tester) async {
      growth.badges = sampleBadges();
      await start(tester);
      await openProfileTab(tester);
      await scrollAndTap(tester, find.text('Helper'));
      await tester.pumpAndSettle();
      expect(
        find.text("Private badges can't be shown by your name."),
        findsOne,
      );
      expect(find.text('Show by my name'), findsNothing);
    });

    testWidgets('the leaderboard switch hides my name', (tester) async {
      await start(tester);
      await openProfileTab(tester);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await scrollAndTap(tester, find.text('Show me on leaderboards'));
      await tester.pumpAndSettle();
      expect(profile.leaderboardCalls, [true]);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });

  group("other students' profiles", () {
    final maliha = StudentProfile(
      id: 'u9',
      name: 'Maliha Rahman',
      verified: true,
      universityName: 'Demo University',
      department: 'CSE',
      batch: '60',
      joinedAt: DateTime(2026, 3),
      featuredBadge: const BadgeRef(key: 'connector', tier: 2),
      badges: const [
        EarnedBadge(key: 'verified'),
        EarnedBadge(key: 'connector', tier: 2),
      ],
      roles: const ['cr'],
      invitesJoined: 3,
      posts: [
        sampleIssue(
          id: 'p1',
          kind: PostKind.post,
          body: 'Library is open till 10 pm now',
          author: const PostAuthor(name: 'Maliha Rahman', id: 'u9'),
        ).card,
      ],
    );

    testWidgets('initials when there is no photo; roles, badges, posts', (
      tester,
    ) async {
      growth.profiles['u9'] = maliha;
      await start(tester);
      await open(tester, Routes.student('u9'));
      expect(find.text('Maliha Rahman'), findsWidgets);
      expect(find.text('Demo University'), findsOneWidget);
      expect(find.text('CSE · 60'), findsOneWidget);
      expect(find.text('Joined March 2026'), findsOneWidget);
      expect(find.text('CR'), findsOneWidget, reason: 'role as a pill');
      expect(find.text('Brought 3 friends'), findsOneWidget);
      expect(find.text('Verified student'), findsWidgets);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('Library is open till 10 pm now'), findsOneWidget);

      final avatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(avatar.photoVersion, isNull);
      expect(avatar.googlePhotoUrl, isNull);
      expect(
        find.descendant(of: find.byType(UserAvatar), matching: find.text('MR')),
        findsOneWidget,
        reason: 'initials',
      );
    });

    testWidgets('no named posts yet; a missing profile is explained', (
      tester,
    ) async {
      growth.profiles['u9'] = StudentProfile(id: 'u9', name: 'Maliha Rahman');
      await start(tester);
      await open(tester, Routes.student('u9'));
      expect(find.text('No named posts yet.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await open(tester, Routes.student('nobody'));
      expect(find.text("This profile isn't available."), findsOneWidget);
    });

    testWidgets('a named author opens the profile, an anonymous one does not', (
      tester,
    ) async {
      growth.profiles['u9'] = maliha;
      growth.profiles['u10'] = StudentProfile(id: 'u10', name: 'Nabil Hasan');
      voice.issues.addAll([
        sampleIssue(
          id: 'i1',
          kind: PostKind.post,
          body: 'Anyone for study group?',
          author: const PostAuthor(
            name: 'Maliha Rahman',
            id: 'u9',
            featuredBadge: BadgeRef(key: 'connector', tier: 2),
          ),
        ),
        sampleIssue(id: 'i2', kind: PostKind.post, body: 'Secret post'),
      ]);
      voice.commentsByIssue['i1'] = [
        IssueComment(
          id: 'c1',
          body: 'Count me in',
          createdAt: DateTime(2026, 10, 27, 9),
          author: const PostAuthor(name: 'Nabil Hasan', id: 'u10'),
        ),
        IssueComment(
          id: 'c2',
          body: 'Me too',
          handle: '7KQF',
          createdAt: DateTime(2026, 10, 27, 10),
        ),
        IssueComment(
          id: 'c3',
          body: 'A name without an id',
          createdAt: DateTime(2026, 10, 27, 11),
          author: const PostAuthor(name: 'Old Name'),
        ),
      ];
      await start(tester);

      await open(tester, Routes.campusIssue('i2'));
      await tester.tap(find.text('Anonymous'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await open(tester, Routes.campusIssue('i1'));
      expect(
        find.byWidgetPredicate(
          (w) => w is CsBadgeIcon && w.badgeKey == 'connector',
        ),
        findsOneWidget,
        reason: 'featured badge by the name',
      );
      await tester.tap(find.text('Nabil Hasan'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student 7KQF'));
      await tester.tap(find.text('Old Name'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsNothing);

      await tester.tap(find.text('Maliha Rahman').first);
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsOneWidget);
    });

    testWidgets('class members show the badge and open the profile', (
      tester,
    ) async {
      growth.profiles['u9'] = maliha;
      classes.mine.add(sampleGroup(role: GroupRole.cr));
      classes.membersOf['g-cse'] = const [
        GroupMember(userId: 'u1', name: 'Rafi', role: GroupRole.cr, isMe: true),
        GroupMember(
          userId: 'u9',
          name: 'Maliha Rahman',
          role: GroupRole.member,
          featuredBadge: BadgeRef(key: 'connector', tier: 2),
        ),
      ];
      await start(tester);
      await open(tester, Routes.groupMembers('g-cse'));
      expect(find.byType(CsBadgeIcon), findsOneWidget);
      await tester.tap(find.text('Maliha Rahman'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsOneWidget);
      expect(find.text('Joined March 2026'), findsOneWidget);
    });
  });

  group('campaigns', () {
    testWidgets('Today: title, top prize, countdown, rank and score', (
      tester,
    ) async {
      growth.campaignList = [sampleCampaign(now: now)];
      await start(tester);
      expect(find.text('Invite and win'), findsOneWidget);
      expect(find.text('Top prize: A phone'), findsOneWidget);
      expect(find.text('LIVE · 5d 3h left'), findsOneWidget);
      expect(find.text('Rank 12 · 4 points'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Invite friends'));
      await tester.pumpAndSettle();
      expect(shared.single, contains('/r/abcd1234'));
    });

    testWidgets('Today: nothing without a live campaign; hours when close', (
      tester,
    ) async {
      growth.campaignList = [
        sampleCampaign(now: now, status: CampaignStatus.announced),
      ];
      await start(tester);
      expect(find.text('Invite and win'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      growth.campaignList = [
        sampleCampaign(
          now: now,
          endsIn: const Duration(hours: 2, minutes: 10),
          rank: null,
        ),
      ];
      await start(tester);
      expect(find.text('LIVE · 2h 10m left'), findsOneWidget);
      expect(
        find.text('Not ranked yet · earn points to climb'),
        findsOneWidget,
      );
    });

    final all = Leaderboard(
      rows: const [
        LeaderboardRow(
          rank: 1,
          name: 'Mim Akter',
          university: 'DIU',
          score: 9,
          userId: 'u7',
          featuredBadge: BadgeRef(key: 'connector', tier: 3),
        ),
        LeaderboardRow(
          rank: 2,
          name: 'A student at BUET',
          university: 'BUET',
          score: 7,
        ),
      ],
      me: const LeaderboardRow(
        rank: 12,
        name: 'Rafi',
        university: 'Demo University',
        score: 4,
        me: true,
        userId: 'u1',
      ),
    );

    testWidgets('leaderboard: scope switch, my row pinned, hidden names', (
      tester,
    ) async {
      growth.campaignList = [sampleCampaign(now: now)];
      growth.boards[LeaderboardScope.all] = all;
      growth.boards[LeaderboardScope.university] = const Leaderboard(
        rows: [LeaderboardRow(rank: 1, name: 'Tania', score: 5, userId: 'u8')],
        me: LeaderboardRow(rank: 3, name: 'Rafi', score: 4, me: true),
      );
      growth.profiles['u7'] = StudentProfile(id: 'u7', name: 'Mim Akter');
      await start(tester);
      await open(tester, Routes.campaign('c1'));

      expect(find.text('PRIZES'), findsOneWidget);
      expect(find.text('A phone'), findsOneWidget);
      expect(find.text('Rank 1'), findsOneWidget);
      expect(find.text('Ranks 4–10'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Bangladesh'), findsOneWidget);
      expect(find.text('Mim Akter'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CsBadgeIcon && w.badgeKey == 'connector' && w.tier == 3,
        ),
        findsOneWidget,
      );
      expect(find.text('9 points'), findsOneWidget);
      expect(find.text('Rafi'), findsOneWidget, reason: 'my row, pinned');
      expect(
        find.text(
          "A friend counts once they're verified and use the app on 3 days.",
        ),
        findsOneWidget,
      );
      expect(find.text('Rules'), findsOneWidget);

      // A hidden student shows as the server says and opens nothing.
      await scrollAndTap(tester, find.text('A student at BUET'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsNothing);

      await scrollAndTap(tester, find.text('Mim Akter'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfilePage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'My university'));
      await tester.pumpAndSettle();
      expect(growth.scopesAsked.last, LeaderboardScope.university);
      expect(find.text('Tania'), findsOneWidget);
      expect(find.text('Mim Akter'), findsNothing);
    });

    testWidgets('ways to earn: rules, my progress, the CR section, share', (
      tester,
    ) async {
      growth.campaignList = [
        sampleCampaign(
          now: now,
          score: 42,
          missions: const [
            CampaignMission(
              key: 'invite',
              points: 10,
              per: MissionPer.friend,
              count: 3,
              earned: 30,
            ),
            CampaignMission(
              key: 'otherCampus',
              points: 5,
              per: MissionPer.friend,
              count: 1,
              earned: 5,
            ),
            CampaignMission(
              key: 'joinSection',
              points: 2,
              per: MissionPer.once,
              count: 1,
              max: 1,
              earned: 2,
            ),
            CampaignMission(
              key: 'bloodDonor',
              points: 3,
              per: MissionPer.once,
              max: 1,
            ),
            CampaignMission(
              key: 'busShare',
              points: 2,
              per: MissionPer.day,
              count: 2,
              max: 10,
              earned: 4,
            ),
            CampaignMission(
              key: 'sectionSetup',
              points: 15,
              per: MissionPer.section,
              max: 2,
            ),
          ],
          section: const CampaignSectionProgress(
            groupId: 'g-cse',
            name: 'CSE 40 A',
            slots: 3,
            members: 7,
          ),
        ),
      ];
      await start(tester);
      expect(find.text('Next: Become a blood donor · +3'), findsOneWidget);
      await open(tester, Routes.campaign('c1'));

      expect(find.text('WAYS TO EARN POINTS'), findsOneWidget);
      expect(find.text("You're in the race"), findsOneWidget);
      expect(find.text('42 points'), findsOneWidget);
      expect(
        find.text('For each friend who joins · 3 friends · +35'),
        findsOneWidget,
      );
      expect(find.text('Extra for each friend'), findsOneWidget);
      expect(find.text('Other university'), findsOneWidget);
      expect(find.text('A friend from another university'), findsNothing);
      expect(find.text('Done · +2'), findsOneWidget);
      expect(find.text('Once'), findsOneWidget);
      expect(
        find.text('Each day someone watches · up to 10 days · 2/10 days · +4'),
        findsOneWidget,
      );
      expect(
        find.text(
          '5+ classes and 5+ verified members · up to 2 · CSE 40 A: 3/5 classes · 5/5 members',
        ),
        findsOneWidget,
      );

      await scrollAndTap(tester, find.text('Invite a friend'));
      await tester.pumpAndSettle();
      expect(shared.single, contains('/r/abcd1234'));
    });

    testWidgets('not in the prize race: points, friends still needed', (
      tester,
    ) async {
      growth.campaignList = [
        sampleCampaign(
          now: now,
          rank: null,
          score: 23,
          eligible: false,
          myOtherCampus: 1,
          myOwnCampus: 1,
        ),
      ];
      await start(tester);
      expect(
        find.text('23 points · not in the prize race yet'),
        findsOneWidget,
      );
      // My own university comes first.
      expect(
        find.text('Next: 2 more friends from your university'),
        findsOneWidget,
      );
      await open(tester, Routes.campaign('c1'));
      expect(find.text('Enter the prize race'), findsOneWidget);
      expect(find.text('Needed to win a prize'), findsOneWidget);
      expect(find.text('Your university'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Other universities'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await scrollAndTap(tester, find.text('Enter the prize race'));
      await tester.pumpAndSettle();
      expect(shared.single, contains('/r/abcd1234'));
    });

    testWidgets('section challenge: goal, prize, my section, the board', (
      tester,
    ) async {
      growth.campaignList = [
        Campaign(
          id: 'c1',
          title: 'Invite and win',
          status: CampaignStatus.live,
          startsAt: now.subtract(const Duration(days: 1)),
          endsAt: now.add(const Duration(days: 5)),
          sectionPrize: 'Tea for the class',
        ),
      ];
      growth.sectionBoard = const SectionBoard(
        rows: [
          SectionRow(
            rank: 1,
            groupId: 'g1',
            name: 'EEE 52 B',
            university: 'BUET',
            members: 31,
            slots: 9,
            champion: true,
          ),
          SectionRow(
            rank: 2,
            groupId: 'g-cse',
            name: 'CSE 40 A',
            university: 'Demo University',
            members: 12,
            slots: 3,
          ),
        ],
        mine: SectionRow(
          rank: 2,
          groupId: 'g-cse',
          name: 'CSE 40 A',
          members: 12,
          slots: 3,
        ),
      );
      await start(tester);
      await open(tester, Routes.campaign('c1'));
      await tester.scrollUntilVisible(find.text('EEE 52 B'), 200);
      expect(find.text('SECTION CHALLENGE'), findsOneWidget);
      expect(
        find.text(
          '25 verified members and 5 classes: the whole section gets the '
          'Champion section badge',
        ),
        findsOneWidget,
      );
      expect(find.text('Top section wins: Tea for the class'), findsOneWidget);
      expect(find.text('Your section · CSE 40 A'), findsOneWidget);
      expect(find.text('12/25'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('31 members'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CsBadgeIcon && w.badgeKey == 'champion_section',
        ),
        findsNWidgets(2),
        reason: 'the goal medal and the champion row',
      );
    });

    testWidgets('finisher reward: number checked, then sent', (tester) async {
      growth.campaignList = [
        Campaign(
          id: 'c1',
          title: 'Invite and win',
          status: CampaignStatus.live,
          startsAt: now.subtract(const Duration(days: 1)),
          endsAt: now.add(const Duration(days: 5)),
          finisherReward: const FinisherReward(
            title: '20 TK recharge',
            count: 50,
            left: 13,
          ),
          finisher: const CampaignFinisher(position: 37, inReward: true),
        ),
      ];
      await start(tester);
      await open(tester, Routes.campaign('c1'));
      expect(find.text("You're finisher #37"), findsNWidgets(2));
      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.widgetWithText(FilledButton, 'Get your reward'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter an 11-digit number starting with 01'),
        findsOneWidget,
      );
      expect(growth.finisherClaims, isEmpty);
      await tester.enterText(find.byType(TextFormField), '01712345678');
      await tester.tap(find.widgetWithText(FilledButton, 'Get your reward'));
      await tester.pumpAndSettle();
      expect(growth.finisherClaims, [('c1', '01712345678')]);
      expect(
        find.text("Got it. We'll send 20 TK recharge to your number."),
        findsOneWidget,
      );
    });

    testWidgets('finisher reward line before I finish', (tester) async {
      growth.campaignList = [
        sampleCampaign(now: now, eligible: false, myOtherCampus: 0).copyWith(),
      ];
      growth.campaignsById['c1'] = Campaign(
        id: 'c1',
        title: 'Invite and win',
        status: CampaignStatus.live,
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 5)),
        eligible: false,
        finisherReward: const FinisherReward(
          title: '20 TK recharge',
          count: 50,
          left: 13,
        ),
      );
      await start(tester);
      await open(tester, Routes.campaign('c1'));
      expect(
        find.text('First 50 in the race get 20 TK recharge · 13 left'),
        findsOneWidget,
      );
    });

    testWidgets('share card: my place and a QR of my link', (tester) async {
      growth.campaignList = [sampleCampaign(now: now, rank: 3, score: 42)];
      await start(tester);
      await open(tester, Routes.campaign('c1'));
      await tester.tap(find.byTooltip('Share my card'));
      await tester.pumpAndSettle();
      expect(find.text('Rank 3 · 42 points'), findsWidgets);
      expect(find.text('Scan to join'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('varsitykotha.com/r/abcd1234'), findsOneWidget);
    });

    testWidgets('winner: the claim form checks the fields, then sends', (
      tester,
    ) async {
      growth.campaignList = [
        sampleCampaign(
          now: now,
          status: CampaignStatus.announced,
          won: const CampaignWin(rank: 1, prize: 'A phone'),
        ),
      ];
      await start(tester);
      await open(tester, Routes.campaign('c1'));
      expect(find.text('You won!'), findsOneWidget);
      expect(find.text('Rank 1 · A phone'), findsOneWidget);

      await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();
      expect(find.text('Write your full name.'), findsOneWidget);
      expect(find.text('Write a phone number we can call.'), findsOneWidget);
      expect(find.text('Write where to deliver the prize.'), findsOneWidget);
      expect(growth.prizeClaims, isEmpty);

      Future<void> fill(String label, String text) async {
        final f = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(f);
        await tester.enterText(f, text);
      }

      await fill('Full name', 'Rafi Ahmed');
      await fill('Phone number', '123');
      await fill('Delivery address', 'House 4, Road 2, Savar');
      await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();
      expect(find.text('Write a phone number we can call.'), findsOneWidget);

      await fill('Phone number', '01712 345678');
      await fill('Note (optional)', 'After 5 pm please');
      await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();
      final (id, claim) = growth.prizeClaims.single;
      expect(id, 'c1');
      expect(claim.fullName, 'Rafi Ahmed');
      expect(claim.phone, '01712 345678');
      expect(claim.address, 'House 4, Road 2, Savar');
      expect(claim.note, 'After 5 pm please');
      expect(find.text("We'll contact you"), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send'), findsNothing);
    });

    testWidgets('winner who already claimed sees "We\'ll contact you"', (
      tester,
    ) async {
      growth.campaignList = [
        sampleCampaign(
          now: now,
          status: CampaignStatus.announced,
          won: const CampaignWin(rank: 1, prize: 'A phone', claimed: true),
        ),
      ];
      await start(tester);
      await open(tester, Routes.campaign('c1'));
      expect(find.text('You won!'), findsOneWidget);
      expect(find.text("We'll contact you"), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send'), findsNothing);
    });

    testWidgets('Profile lists live and recent campaigns', (tester) async {
      growth.campaignList = [
        sampleCampaign(now: now),
        sampleCampaign(now: now, status: CampaignStatus.announced),
      ];
      await start(tester);
      await openProfileTab(tester);
      expect(find.text('PRIZE CAMPAIGNS'), findsOneWidget);
      expect(find.text('Live · 5d 3h left'), findsOneWidget);
      expect(find.text('Winners announced'), findsOneWidget);
    });
  });

  group('referral claim', () {
    testWidgets('a waiting referral is claimed once, after sign-in', (
      tester,
    ) async {
      PendingReferral.save('abcd1234', source: 'join');
      await start(tester);
      expect(growth.claimedReferrals, [('abcd1234', 'join')]);
      expect(PendingReferral.value, isNull);
    });

    testWidgets('nothing waiting: nothing is sent', (tester) async {
      await start(tester);
      expect(growth.claimedReferrals, isEmpty);
    });

    testWidgets('a refused claim (too late, own code…) is ignored', (
      tester,
    ) async {
      growth.referralFailure = const RejectedFailure(code: 'REFERRAL_TOO_LATE');
      PendingReferral.save('abcd1234', source: 'link');
      await start(tester);
      expect(growth.claimedReferrals, hasLength(1));
      expect(PendingReferral.value, isNull, reason: 'not tried again');
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('offline: kept for the next time', (tester) async {
      growth.referralFailure = const NetworkFailure();
      PendingReferral.save('abcd1234', source: 'link');
      await start(tester);
      expect(PendingReferral.value, (code: 'abcd1234', source: 'link'));
    });

    testWidgets('an invite link opens Today and claims with source link', (
      tester,
    ) async {
      await start(tester);
      await open(tester, '/r/abcd1234');
      expect(growth.claimedReferrals, [('abcd1234', 'link')]);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('a class invite with ?ref= claims with source join', (
      tester,
    ) async {
      classes.others['ABCDEF'] = sampleGroup();
      await start(tester);
      await open(tester, '/join/ABCDEF?ref=abcd1234');
      expect(growth.claimedReferrals, [('abcd1234', 'join')]);
      expect(find.text('Join your class group'), findsOneWidget);
    });
  });

  group('pushes', () {
    testWidgets('referral_joined opens Invite friends', (tester) async {
      await start(tester);
      push.openedNotes.add(const PushNote(data: {'type': 'referral_joined'}));
      await tester.pumpAndSettle();
      expect(find.text('INVITE FRIENDS'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Share'), findsOneWidget);
    });

    testWidgets('badge_earned opens Badges', (tester) async {
      growth.badges = sampleBadges();
      await start(tester);
      push.openedNotes.add(
        const PushNote(data: {'type': 'badge_earned', 'badge': 'connector'}),
      );
      await tester.pumpAndSettle();
      expect(find.text('BADGES'), findsOneWidget);
      expect(find.text('Connector'), findsOneWidget);
    });

    testWidgets('campaign_won opens the campaign', (tester) async {
      growth.campaignList = [
        sampleCampaign(
          now: now,
          status: CampaignStatus.announced,
          won: const CampaignWin(rank: 1, prize: 'A phone'),
        ),
      ];
      await start(tester);
      push.openedNotes.add(
        const PushNote(data: {'type': 'campaign_won', 'campaignId': 'c1'}),
      );
      await tester.pumpAndSettle();
      expect(find.text('You won!'), findsOneWidget);
    });
  });

  group('Bangla', () {
    testWidgets('invites, badges and campaigns read in Bangla with digits', (
      tester,
    ) async {
      growth.stats = const ReferralStats(
        code: 'abcd1234',
        link: 'https://varsitykotha.com/r/abcd1234',
        invited: 12,
        joined: 8,
        pending: [PendingFriend(name: 'Rafi', verified: true, activeDays: 2)],
      );
      growth.badges = sampleBadges();
      growth.campaignList = [sampleCampaign(now: now)];
      growth.boards[LeaderboardScope.all] = const Leaderboard(
        rows: [
          LeaderboardRow(rank: 1, name: 'Mim Akter', score: 9, userId: 'u7'),
        ],
        me: LeaderboardRow(rank: 12, name: 'Rafi', score: 4, me: true),
      );
      await start(tester, locale: const Locale('bn'));
      expect(find.textContaining('১২'), findsWidgets, reason: 'rank 12');
      await tester.tap(find.text('প্রোফাইল'));
      await tester.pumpAndSettle();
      expect(find.text('১২ জনকে ডেকেছ · ৮ জন যোগ দিয়েছে'), findsOneWidget);
      expect(find.text('ব্যাজ'), findsOneWidget);
      expect(
        find.text('Connector'),
        findsNothing,
        reason: 'not left in English',
      );
      expect(find.text('কানেক্টর'), findsOneWidget);
      expect(find.text('লিডারবোর্ডে আমাকে দেখাও'), findsOneWidget);

      await open(tester, Routes.campaign('c1'));
      expect(find.text('লিডারবোর্ড'), findsWidgets);
      expect(find.text('বাংলাদেশ'), findsOneWidget);
      expect(find.text('আমার বিশ্ববিদ্যালয়'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
