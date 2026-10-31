import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tiers have their own ring colour; badges without tiers have none', () {
    expect(CsTierColors.of(1), CsTierColors.bronze);
    expect(CsTierColors.of(2), CsTierColors.silver);
    expect(CsTierColors.of(3), CsTierColors.gold);
    expect(CsTierColors.of(0), isNull);
  });

  test('every badge key has an icon; unknown keys get the medal', () {
    for (final k in [
      'verified',
      'founding',
      'cr',
      'campus_admin',
      'bus_rep',
      'official',
      'blood_donor',
      'life_saver',
      'bus_buddy',
      'section_builder',
      'connector',
      'bug_hunter',
      'helper',
      'campus_voice',
    ]) {
      expect(CsIcons.badge(k), isNot(CsIcons.badge('unknown')), reason: k);
    }
  });

  testWidgets('a medal: gold rim and three stars at tier 3; locked is grey', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: CsTheme.light,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(
              body: Row(
                children: [
                  CsBadgeIcon(badgeKey: 'connector', tier: 3, size: 52),
                  CsBadgeIcon(badgeKey: 'cr', size: 18),
                  CsBadgeIcon(badgeKey: 'cr', locked: true),
                ],
              ),
            );
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final gold = CsBadgeIcon.look(ctx, 'connector', tier: 3);
    expect(gold.rim, CsTierColors.metal(3));
    expect(gold.stars, 3);
    expect(gold.hexagon, isFalse);
    expect(CsBadgeIcon.look(ctx, 'cr').hexagon, isTrue);
    expect(CsBadgeIcon.look(ctx, 'cr').stars, 0);
    final locked = CsBadgeIcon.look(ctx, 'connector', tier: 3, locked: true);
    expect(locked.rim, isNot(contains(CsTierColors.gold)));
    expect(locked.stars, 0);
  });
}
