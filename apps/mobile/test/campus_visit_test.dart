import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/features/voice/data/voice_cache.dart';

import 'helpers/fakes.dart';
import 'voice_fakes.dart';

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 12));
  tearDown(() => appNow = DateTime.now);

  late FakeVoiceRepository voice;

  const du = CampusSummary(
    id: 'uni-du',
    slug: 'du',
    name: 'University of Dhaka',
    nameBn: 'ঢাকা বিশ্ববিদ্যালয়',
    city: 'Dhaka',
    kind: 'public',
    students: 1240,
    posts7d: 37,
  );

  final duPost = IssueCard(
    id: 'p-du',
    kind: PostKind.post,
    category: IssueCategory.event,
    title: '',
    preview: 'Book fair at TSC starts tomorrow!',
    status: IssueStatus.open,
    createdAt: DateTime(2026, 10, 27, 9),
    meTooCount: 5,
    reactions: const {Reaction.like: 5},
    visitor: true,
  );

  setUp(() {
    voice = FakeVoiceRepository()
      ..campusList.add(du)
      ..campusProfiles['du'] = const CampusProfile(
        summary: du,
        website: 'https://du.ac.bd',
        classGroups: 86,
        busRoutes: 12,
      )
      ..visitPosts['uni-du'] = [duPost]
      ..issues.add(
        Issue(card: duPost, body: 'Book fair at TSC starts tomorrow!'),
      );
  });

  Future<void> start(WidgetTester tester, {bool flag = true}) async {
    usePhoneScreen(tester);
    final config = FakeAppConfigRepository()
      ..config = AppConfig(
        minSupportedBuild: 1,
        features: {'myClass': true, 'campusVoice': true, 'visitCampus': flag},
      );
    final (auth, _) = await registerFakes(
      config: config,
      voice: voice,
      voiceCache: MemoryVoiceCache(),
    );
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  testWidgets('visit another campus: profile, posts, react, read only', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Visit other campuses'));
    await tester.pumpAndSettle();
    expect(find.text('MOST ACTIVE THIS WEEK'), findsOneWidget);
    expect(find.text('Dhaka · Public · 1,240 students'), findsOneWidget);
    expect(find.text('37 posts this week'), findsOneWidget);

    await tester.tap(find.text('University of Dhaka'));
    await tester.pumpAndSettle();
    expect(voice.lastVisited, 'uni-du');
    expect(find.text('ঢাকা বিশ্ববিদ্যালয়'), findsOneWidget);
    expect(find.text('86'), findsOneWidget, reason: 'class groups');
    expect(
      find.textContaining("You're visiting another university"),
      findsOneWidget,
    );
    expect(find.text('Issues'), findsNothing, reason: 'issues stay inside');
    expect(find.text('Book fair at TSC starts tomorrow!'), findsOneWidget);

    // React works for visitors.
    await tester.tap(find.text('Like'));
    await tester.pumpAndSettle();
    expect(voice.issues.single.card.myReaction, Reaction.like);

    // The post opens read-only: no comment box.
    await tester.tap(find.text('Book fair at TSC starts tomorrow!'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("You're visiting another university"),
      findsOneWidget,
    );
    expect(find.text('Add a comment'), findsNothing);
  });

  testWidgets('while it is off, Visit stays "coming soon"', (tester) async {
    await start(tester, flag: false);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Visit other campuses'),
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Visit other campuses'));
    await tester.pumpAndSettle();
    expect(find.text('MOST ACTIVE THIS WEEK'), findsNothing);
  });

  testWidgets('a post can stay inside the university', (tester) async {
    await start(tester);
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Students of all universities can see this (they can't comment).",
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextField).first,
      'Hall 2 only: water at 6',
    );
    await tester.dragUntilVisible(
      find.text('Only my university'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Only my university'));
    await tester.pumpAndSettle();
    expect(
      find.text('Only students of your university can see this.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();
    expect(voice.created.single.campusOnly, isTrue);
    expect(voice.created.single.toJson()['campusOnly'], isTrue);
  });
}
