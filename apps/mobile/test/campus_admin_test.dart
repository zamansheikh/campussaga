import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';

import 'campus_fakes.dart';
import 'helpers/fakes.dart';

const adminUser = UserProfile(
  id: 'u1',
  email: 'rafi@cse.demo.ac.bd',
  university: University(
    id: 'uni1',
    slug: 'demo-university',
    name: 'Demo University',
  ),
  role: 'student',
  displayName: 'Rafi',
  department: 'CSE',
  batch: '61',
  verified: true,
  campusAdmin: true,
);

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 12));
  tearDown(() => appNow = DateTime.now);

  late FakeCampusAdminRepository admin;

  setUp(() => admin = FakeCampusAdminRepository());

  Future<void> openAdmin(
    WidgetTester tester, {
    UserProfile user = adminUser,
  }) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes(campusAdmin: admin);
    auth.savedUser = user;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Campus admin · Demo University'));
    await tester.pumpAndSettle();
  }

  Future<void> goTab(WidgetTester tester, String name) async {
    final tab = find.widgetWithText(Tab, name);
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  testWidgets('only campus admins see the entry', (tester) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes(campusAdmin: admin);
    auth.savedUser = testUser; // not a campus admin
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Campus admin'), findsNothing);
  });

  testWidgets('the inbox shows waiting students and what needs attention', (
    tester,
  ) async {
    await openAdmin(tester);
    expect(find.text('WAITING FOR VERIFICATION'), findsOneWidget);
    expect(find.text('Mim Akter'), findsOneWidget);
    expect(find.text('1 report waiting'), findsOneWidget);
    expect(find.text('1 section without a CR'), findsOneWidget);
    expect(find.text('1 open blood request'), findsOneWidget);
    expect(find.textContaining('Vouched by Tanvir'), findsOneWidget);

    // A count leads to its tab.
    await tester.tap(find.text('1 report waiting'));
    await tester.pumpAndSettle();
    expect(find.text('Selling fake notes, DM me'), findsOneWidget);
  });

  testWidgets('students: filters, then verify one and see the history', (
    tester,
  ) async {
    await openAdmin(tester);
    await goTab(tester, 'Students');
    expect(find.text('Mim Akter'), findsOneWidget);
    expect(find.text('Sadia Rahman'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Verified'));
    await tester.pumpAndSettle();
    expect(find.text('Sadia Rahman'), findsOneWidget);
    expect(find.text('Mim Akter'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Not verified'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mim Akter'));
    await tester.pumpAndSettle();
    expect(find.text('CSE · 61'), findsOneWidget);
    expect(find.text('CSE 61 · A'), findsOneWidget, reason: 'groups');

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('verify:s1'));
    expect(find.text('Mim Akter is verified'), findsOneWidget);
    expect(find.text('Remove verification'), findsOneWidget);
    expect(
      find.textContaining('Verified by campus admin Rafi'),
      findsOneWidget,
    );
  });

  testWidgets('students: search narrows the list', (tester) async {
    await openAdmin(tester);
    await goTab(tester, 'Students');
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Karim Hasan'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'sadia');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Sadia Rahman'), findsOneWidget);
    expect(find.text('Karim Hasan'), findsNothing);
  });

  testWidgets('remove verification asks for a reason', (tester) async {
    await openAdmin(tester);
    await goTab(tester, 'Students');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Verified'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karim Hasan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove verification'));
    await tester.pumpAndSettle();

    // Empty reason: refused.
    await tester.tap(find.widgetWithText(TextButton, 'Remove verification'));
    await tester.pumpAndSettle();
    expect(find.text('Write a reason.'), findsOneWidget);
    expect(admin.calls.where((c) => c.startsWith('unverify')), isEmpty);

    await tester.enterText(find.byType(TextField).last, 'Not in our section');
    await tester.tap(find.widgetWithText(TextButton, 'Remove verification'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('unverify:s3:Not in our section'));
    expect(find.text('Verification removed'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('email-verified students can only be changed by the team', (
    tester,
  ) async {
    await openAdmin(tester);
    await goTab(tester, 'Students');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Verified'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sadia Rahman'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Verified by university email: only the VarsityKotha team can change this.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Remove verification'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
    expect(admin.calls.where((c) => c.startsWith('unverify')), isEmpty);
  });

  testWidgets('block and allow vouching', (tester) async {
    await openAdmin(tester);
    await goTab(tester, 'Students');
    await tester.tap(find.text('Mim Akter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block vouching'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Vouched for friends');
    await tester.tap(find.widgetWithText(TextButton, 'Block vouching'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('block:s1:Vouched for friends'));
    expect(find.text("Can't vouch"), findsOneWidget);

    await tester.tap(find.text('Allow vouching again'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('unblock:s1'));
    expect(find.text("Can't vouch"), findsNothing);
  });

  testWidgets('ask the VarsityKotha team sends an escalation', (tester) async {
    await openAdmin(tester);
    await goTab(tester, 'Students');
    await tester.tap(find.text('Mim Akter'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Ask the VarsityKotha team'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Looks like a fake');
    await tester.tap(find.widgetWithText(TextButton, 'Send'));
    await tester.pumpAndSettle();
    expect(admin.escalations.single, (
      EscalationKind.student,
      'Looks like a fake',
      's1',
    ));
    expect(find.text('Sent to the VarsityKotha team'), findsOneWidget);
  });

  testWidgets('sections: those without a CR first; make someone CR', (
    tester,
  ) async {
    await openAdmin(tester);
    await goTab(tester, 'Sections');
    final noCr = find.text('No CR');
    expect(noCr, findsOneWidget);
    // Without a CR first.
    expect(
      tester.getTopLeft(find.text('CSE 61 · A')).dy,
      lessThan(tester.getTopLeft(find.text('EEE 60 · B')).dy),
    );

    await tester.tap(find.text('CSE 61 · A'));
    await tester.pumpAndSettle();
    expect(find.text('Sadia Rahman'), findsOneWidget);
    await tester.tap(find.text('Make CR').first);
    await tester.pumpAndSettle();
    expect(admin.calls, contains('makeCr:sec1:s2'));
    expect(find.text('Sadia Rahman is CR now'), findsOneWidget);
    expect(find.text('CR'), findsWidgets, reason: 'CR badge');
    expect(find.text('Remove CR'), findsWidgets);

    await tester.tap(find.text('Remove CR').first);
    await tester.pumpAndSettle();
    expect(admin.calls, contains('removeCr:sec1:s2'));
  });

  testWidgets('reports: hide, restore and dismiss; tap opens the post', (
    tester,
  ) async {
    await openAdmin(tester);
    await goTab(tester, 'Reports');
    expect(find.text('3 reports'), findsOneWidget);
    expect(find.text('Spam'), findsOneWidget);

    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('report:issue:r1:hide'));
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Hidden'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('report:issue:r1:restore'));

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('report:issue:r1:dismiss'));
    expect(find.text('No reported posts.'), findsOneWidget);
  });

  testWidgets('blood: close a request with a reason', (tester) async {
    await openAdmin(tester);
    await goTab(tester, 'Blood');
    expect(find.text('B+ · Enam Medical'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Got blood');
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('closeBlood:b1:Got blood'));
    expect(find.text('No open blood requests.'), findsOneWidget);
  });

  testWidgets('bus reps: add by picking a student, and remove', (tester) async {
    await openAdmin(tester);
    await goTab(tester, 'Bus reps');
    expect(find.text('Imran'), findsOneWidget);

    await tester.tap(find.text('Add bus rep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sadia Rahman'));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('addRep:s2'));
    expect(find.text('Sadia Rahman'), findsOneWidget);

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();
    expect(admin.calls, contains('removeRep:rep1'));
    expect(find.text('Imran'), findsNothing);
  });

  testWidgets('a student who is not an admin is told', (tester) async {
    admin.failure = const ForbiddenFailure(code: 'NOT_CAMPUS_ADMIN');
    await openAdmin(tester);
    expect(find.text("You're not a campus admin."), findsWidgets);
  });
}
