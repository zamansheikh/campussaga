import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/router.dart';
import 'package:varsitykotha/features/sponsors/deals_page.dart';
import 'package:varsitykotha/features/sponsors/promo_actions.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'growth_fakes.dart';
import 'helpers/fakes.dart';
import 'voice_fakes.dart';

/// Ads the server would give, by placement, and what the app sent back.
class FakeSponsorsRepository implements SponsorsRepository {
  final byPlacement = <String, List<Promo>>{};
  final events = <PromoEvent>[];
  final asked = <String>[];

  @override
  Future<List<Promo>> promos(String placement, {String lang = 'en'}) async {
    asked.add(placement);
    return byPlacement[placement] ?? const [];
  }

  @override
  Future<void> sendEvents(List<PromoEvent> e) async => events.addAll(e);

  List<(String, PromoEventType)> get sent => [
    for (final e in events) (e.promoId, e.type),
  ];
}

const _cafe = PromoSponsor(name: 'Cafe Nirob');

Promo _card({String id = 'p1', PromoLink? link}) => Promo(
  id: id,
  kind: PromoKind.card,
  placement: PromoPlacement.today,
  sponsor: _cafe,
  title: '20% off near campus',
  body: 'Show your student ID at the counter.',
  cta: 'Get offer',
  link: link ?? const PromoLink(web: false, url: '/deals'),
  why: 'Shown to students at Demo University',
  targeted: true,
);

Promo _deal({
  required String id,
  required String title,
  String? code,
  bool targeted = false,
}) => Promo(
  id: id,
  kind: PromoKind.deal,
  placement: PromoPlacement.deals,
  sponsor: _cafe,
  title: title,
  body: 'For students only.',
  code: code,
  terms: 'One per student.',
  expiresAt: DateTime.now().add(const Duration(days: 20)),
  why: targeted ? 'Shown to students at Demo University' : 'Shown to all',
  targeted: targeted,
);

/// The page's main (vertical) list.
final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

void main() {
  late FakeSponsorsRepository sponsors;
  late FakeVoiceRepository voice;
  late FakeGrowthRepository growth;

  setUp(() {
    sponsors = FakeSponsorsRepository();
    voice = FakeVoiceRepository();
    growth = FakeGrowthRepository()..failure = const NetworkFailure();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    phoneShowsCopy = () async => false;
  });

  Future<void> start(WidgetTester tester) async {
    usePhoneScreen(tester);
    final config = FakeAppConfigRepository()
      ..config = const AppConfig(
        minSupportedBuild: 1,
        features: {'myClass': true, 'campusVoice': true, 'bloodDonation': true},
      );
    final (auth, _) = await registerFakes(
      config: config,
      classes: FakeClassGroupRepository()..mine.add(sampleGroup()),
      voice: voice,
      growth: growth,
      sponsors: sponsors,
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

  group('Today', () {
    testWidgets('one sponsored card below the routine; a view after a second '
        'on screen; its button opens the link', (tester) async {
      sponsors.byPlacement[PromoPlacement.today] = [_card()];
      await start(tester);
      await tester.scrollUntilVisible(
        find.text('20% off near campus'),
        200,
        scrollable: _vertical.first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sponsored · Cafe Nirob'), findsOneWidget);
      expect(find.text('Show your student ID at the counter.'), findsOneWidget);

      // Half on screen for a second: one view (sent with the next tap).
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.tap(find.widgetWithText(FilledButton, 'Get offer'));
      await tester.pumpAndSettle();
      expect(sponsors.sent, [
        ('p1', PromoEventType.view),
        ('p1', PromoEventType.tap),
      ]);
      expect(find.byType(DealsPage), findsOneWidget);
    });

    testWidgets('why: who sees it and that sponsors never see you; hiding '
        'folds it away for 7 days', (tester) async {
      sponsors.byPlacement[PromoPlacement.today] = [_card()];
      await start(tester);
      await tester.scrollUntilVisible(
        find.text('20% off near campus'),
        200,
        scrollable: _vertical.first,
      );
      await tester.tap(find.bySemanticsLabel('Why am I seeing this?').first);
      await tester.pumpAndSettle();
      expect(find.text('Shown to students at Demo University'), findsOneWidget);
      expect(
        find.text(
          'Sponsors never see who you are. We only count views and taps '
          'in total.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Hide this ad'));
      await tester.pumpAndSettle();
      expect(find.text('20% off near campus'), findsNothing);
      expect(find.text('Hidden for 7 days'), findsOneWidget);
      expect(sponsors.sent.last, ('p1', PromoEventType.hide));
    });

    testWidgets('nothing shows without an ad', (tester) async {
      await start(tester);
      expect(find.text('Sponsored'), findsNothing);
      expect(sponsors.asked, contains(PromoPlacement.today));
    });
  });

  group('deals', () {
    testWidgets('Explore shows the tile with the count; near you first; '
        'copy puts the code on the clipboard', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      sponsors.byPlacement[PromoPlacement.deals] = [
        _deal(id: 'd1', title: '10% off laptops', code: 'VK10'),
        _deal(id: 'd2', title: 'Free coffee', code: 'VK20', targeted: true),
      ];
      await start(tester);
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Student deals'), findsOneWidget);
      expect(find.text('2 offers'), findsOneWidget);
      await tester.tap(find.text('Student deals'));
      await tester.pumpAndSettle();

      expect(find.text('NEAR YOU'), findsOneWidget);
      expect(find.text('FOR EVERY STUDENT'), findsOneWidget);
      final near = tester.getTopLeft(find.text('Free coffee')).dy;
      final all = tester.getTopLeft(find.text('10% off laptops')).dy;
      expect(near, lessThan(all));

      await tester.tap(find.text('VK20'));
      await tester.pumpAndSettle();
      expect(copied, ['VK20']);
      expect(find.text('Code VK20 copied'), findsOneWidget);
      expect(sponsors.sent.last, ('d2', PromoEventType.copy));

      // Terms open under the deal.
      await tester.tap(find.text('Terms').first);
      await tester.pumpAndSettle();
      expect(find.text('One per student.'), findsOneWidget);
    });

    testWidgets('no tile without deals', (tester) async {
      await start(tester);
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Student deals'), findsNothing);
    });
  });

  testWidgets('Campus feed: a sponsored post after the 12th post, drawn as '
      'a post with no reactions', (tester) async {
    voice.issues.addAll([
      for (var i = 0; i < 14; i++)
        sampleIssue(id: 'i$i', kind: PostKind.post, body: 'Post number $i'),
    ]);
    sponsors.byPlacement[PromoPlacement.campus] = [
      const Promo(
        id: 'f1',
        kind: PromoKind.feed,
        placement: PromoPlacement.campus,
        sponsor: PromoSponsor(name: 'Book Corner'),
        title: 'Second-hand textbooks',
        body: 'Half price for students.',
        cta: 'See books',
        link: PromoLink(web: true, url: 'https://example.com'),
      ),
    ];
    await start(tester);
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Second-hand textbooks'),
      400,
      scrollable: _vertical.first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Book Corner'), findsOneWidget);
    expect(find.text('Sponsored'), findsOneWidget);
    expect(find.text('See books'), findsOneWidget);
    // It sits after the 12th post.
    final ad = tester.getTopLeft(find.text('Second-hand textbooks')).dy;
    await tester.scrollUntilVisible(
      find.text('Post number 12'),
      200,
      scrollable: _vertical.first,
    );
    expect(
      tester.getTopLeft(find.text('Post number 12')).dy,
      greaterThan(tester.getTopLeft(find.text('Second-hand textbooks')).dy),
    );
    expect(ad, isNotNull);
  });

  testWidgets('a short feed shows its one sponsored post at the end', (
    tester,
  ) async {
    voice.issues.addAll([
      for (var i = 0; i < 4; i++)
        sampleIssue(id: 'i$i', kind: PostKind.post, body: 'Post number $i'),
    ]);
    sponsors.byPlacement[PromoPlacement.campus] = [
      const Promo(
        id: 'f1',
        kind: PromoKind.feed,
        placement: PromoPlacement.campus,
        sponsor: PromoSponsor(name: 'Book Corner'),
        title: 'Second-hand textbooks',
      ),
    ];
    await start(tester);
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Second-hand textbooks'),
      300,
      scrollable: _vertical.first,
    );
    expect(find.text('Book Corner'), findsOneWidget);
  });

  testWidgets('a quiet sponsor line at the bottom of Class groups', (
    tester,
  ) async {
    sponsors.byPlacement[PromoPlacement.lineGroups] = [
      const Promo(
        id: 'l1',
        kind: PromoKind.line,
        placement: PromoPlacement.lineGroups,
        sponsor: PromoSponsor(name: 'Swift Travels'),
      ),
    ];
    await start(tester);
    await open(tester, Routes.groups);
    await tester.scrollUntilVisible(
      find.text('Swift Travels'),
      200,
      scrollable: _vertical.first,
    );
    expect(find.text('Supported by'), findsOneWidget);
    expect(find.text('Swift Travels'), findsOneWidget);
  });

  testWidgets('a campaign sponsor: Powered by on the poster', (tester) async {
    growth
      ..failure = null
      ..campaignList = [
        Campaign(
          id: 'c1',
          title: 'Invite and win',
          status: CampaignStatus.live,
          startsAt: DateTime.now().subtract(const Duration(days: 1)),
          endsAt: DateTime.now().add(const Duration(days: 4)),
          sponsor: const CampaignSponsor(name: 'Gadget Hub'),
        ),
      ];
    await start(tester);
    expect(find.text('POWERED BY'), findsOneWidget);
    expect(find.text('Gadget Hub'), findsOneWidget);
    expect(find.byType(CsPoweredBy), findsOneWidget);
  });
}
