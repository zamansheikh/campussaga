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

  testWidgets('a badge icon rings in its tier colour; locked is grey', (
    tester,
  ) async {
    Future<BoxDecoration> ring(Widget w) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CsTheme.light,
          home: Scaffold(body: w),
        ),
      );
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(CsBadgeIcon),
          matching: find.byType(Container),
        ),
      );
      return box.decoration! as BoxDecoration;
    }

    final gold = await ring(const CsBadgeIcon(badgeKey: 'connector', tier: 3));
    expect((gold.border! as Border).top.color, CsTierColors.gold);
    final locked = await ring(
      const CsBadgeIcon(badgeKey: 'connector', tier: 3, locked: true),
    );
    expect((locked.border! as Border).top.color, isNot(CsTierColors.gold));
  });
}
