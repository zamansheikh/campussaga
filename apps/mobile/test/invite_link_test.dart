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

  test('install referrers: join and ref, ref only, join only', () {
    final both = InviteLink.parseReferrer(
      'utm_source=invite&join=KQWRZT&ref=abcd1234',
    );
    expect(both.join, 'KQWRZT');
    expect(both.ref, 'abcd1234');
    final refOnly = InviteLink.parseReferrer('utm_source=invite&ref=ABCD1234');
    expect(refOnly.join, isNull);
    expect(refOnly.ref, 'abcd1234', reason: 'codes are lower case');
    final joinOnly = InviteLink.parseReferrer('utm_source=invite&join=KQWRZT');
    expect(joinOnly.join, 'KQWRZT');
    expect(joinOnly.ref, isNull);
    expect(InviteLink.parseReferrer('ref=short').ref, isNull);
    expect(InviteLink.parseReferrer('ref=abcd-123').ref, isNull);
    expect(InviteLink.parseReferrer(null), (join: null, ref: null));
    // The old reader keeps working.
    expect(InviteLink.fromReferrer('join=KQWRZT&ref=abcd1234'), 'KQWRZT');
  });

  test('a ref in an install referrer is kept for sign-in', () {
    PendingReferral.clear();
    PendingReferral.saveFromReferrer('utm_source=invite&ref=abcd1234');
    expect(PendingReferral.value, (code: 'abcd1234', source: 'link'));
    PendingReferral.clear();
    PendingReferral.saveFromReferrer('join=KQWRZT&ref=abcd1234');
    expect(PendingReferral.value, (code: 'abcd1234', source: 'join'));
    // The first one stays; a bad code is not kept.
    PendingReferral.saveFromReferrer('ref=zzzzzzzz');
    expect(PendingReferral.value?.code, 'abcd1234');
    expect(PendingReferral.take(), (code: 'abcd1234', source: 'join'));
    expect(PendingReferral.value, isNull);
    PendingReferral.save('nope', source: 'link');
    expect(PendingReferral.value, isNull);
  });

  test('class invites share my code, personal links open /r/', () {
    expect(
      InviteLink.link('ABCDEF', ref: 'abcd1234').toString(),
      'https://varsitykotha.com/join/ABCDEF?ref=abcd1234',
    );
    expect(
      InviteLink.link('ABCDEF', ref: 'nonsense!').toString(),
      'https://varsitykotha.com/join/ABCDEF',
    );
    expect(
      InviteLink.personalLink('abcd1234').toString(),
      'https://varsitykotha.com/r/abcd1234',
    );
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
