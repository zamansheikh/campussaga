import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:varsitykotha/app/router.dart';
import 'package:varsitykotha/features/classes/data/invite_link.dart';

import 'classes_test.dart' show signedIn;
import 'helpers/fakes.dart' show sampleGroup;

void main() {
  test('invite links and install referrers', () {
    expect(
      InviteLink.link('ABCDEF').toString(),
      'https://varsitykotha.com/join/ABCDEF',
    );
    expect(InviteLink.code(' abcdef '), 'ABCDEF');
    expect(InviteLink.code('ABCDEI'), isNull, reason: 'no I or O in codes');
    expect(InviteLink.fromReferrer('utm_source=invite&join=KQWRZT'), 'KQWRZT');
    expect(InviteLink.fromReferrer('utm_source=google-play'), isNull);
    expect(InviteLink.fromReferrer(null), isNull);
  });

  testWidgets('an invite link opens the join screen with the group', (
    tester,
  ) async {
    final classes = await signedIn(tester, others: {'ABCDEF': sampleGroup()});
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go(Routes.invite('ABCDEF'));
    await tester.pumpAndSettle();
    expect(find.text('Join your class group'), findsOneWidget);
    expect(find.text('CSE 61 · A'), findsOneWidget, reason: 'looked up');
    await tester.ensureVisible(find.text('Join group'));
    await tester.tap(find.text('Join group'));
    await tester.pumpAndSettle();
    expect(classes.mine.single.id, 'g-cse');
  });

  testWidgets('a code from an install or a signed-out link waits for sign-in', (
    tester,
  ) async {
    PendingInvite.save('ABCDEF');
    await signedIn(tester, others: {'ABCDEF': sampleGroup()});
    expect(find.text('Join your class group'), findsOneWidget);
    expect(find.text('CSE 61 · A'), findsOneWidget);
    expect(PendingInvite.code, isNull, reason: 'used once');
  });
}
