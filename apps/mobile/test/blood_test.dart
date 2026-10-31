import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';

import 'blood_fakes.dart';
import 'helpers/fakes.dart';

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 12));
  tearDown(() => appNow = DateTime.now);

  late FakeBloodRepository blood;

  setUp(() => blood = FakeBloodRepository());

  Future<void> start(
    WidgetTester tester, {
    UserProfile user = testUser,
    bool flag = true,
  }) async {
    usePhoneScreen(tester);
    final config = FakeAppConfigRepository()
      ..config = AppConfig(
        minSupportedBuild: 1,
        features: {'myClass': true, 'bloodDonation': flag},
      );
    final (auth, _) = await registerFakes(config: config, blood: blood);
    auth.savedUser = user;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  Future<void> openBlood(WidgetTester tester) async {
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Blood donation'));
    await tester.pumpAndSettle();
  }

  testWidgets('Explore shows blood donation only while it is on', (
    tester,
  ) async {
    await start(tester, flag: false);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Blood donation'), findsNothing);
  });

  testWidgets('become a donor, then record a donation', (tester) async {
    await start(tester);
    await openBlood(tester);
    expect(find.text('No one needs blood right now'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Become a donor'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(
      tester.widget<FilledButton>(save).onPressed,
      isNull,
      reason: 'pick a group',
    );
    await tester.tap(find.text('O+'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone number'),
      'call me',
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a mobile number like 01712345678.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone number'),
      '০১৭১২ ৩৪৫৬৭৮',
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(blood.donor?.bloodGroup, BloodGroup.oPos);
    expect(blood.donor?.phone, '01712345678', reason: 'Bangla digits work');
    expect(find.text('You can donate now'), findsOneWidget);
    expect(find.text('No donations yet'), findsOneWidget);

    await tester.tap(find.text('I donated today'));
    await tester.pumpAndSettle();
    expect(find.text("Thank you! You've helped save a life."), findsOneWidget);
    expect(find.textContaining('You can donate again from'), findsOneWidget);
    expect(find.text('Donated once'), findsOneWidget);
  });

  testWidgets('ask for blood; donors are told', (tester) async {
    await start(tester);
    await openBlood(tester);
    await tester.tap(find.text('Request blood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B+'));
    await tester.pumpAndSettle();
    expect(
      find.text('Can also receive from: B+ · B− · O+ · O−'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Hospital'),
      'Enam Medical College Hospital',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Area'), 'Savar');
    await scrollAndTap(tester, find.byTooltip('+'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Contact phone'),
      '01812345678',
    );
    await scrollAndTap(tester, find.text('Urgent'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Send request'));
    await tester.pumpAndSettle();

    final d = blood.created.single;
    expect(d.bloodGroup, BloodGroup.bPos);
    expect(d.units, 2);
    expect(d.urgent, isTrue);
    expect(d.contactName, 'Rafi', reason: 'prefilled');
    expect(find.text('14 B+ donors were notified'), findsWidgets);
    // The new request opens.
    expect(find.text('B+ blood needed'), findsOneWidget);
    expect(find.text('Got blood'), findsOneWidget);
  });

  testWidgets('students who are not verified are asked to verify first', (
    tester,
  ) async {
    await start(
      tester,
      user: const UserProfile(
        id: 'u2',
        email: 'someone@gmail.com',
        university: University(id: 'uni1', slug: 'demo', name: 'Demo'),
        role: 'student',
        displayName: 'Mim',
        department: 'CSE',
        batch: '61',
      ),
    );
    await openBlood(tester);
    await tester.tap(find.text('Request blood'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Verify your university email to ask for blood. This keeps requests real.',
      ),
      findsOneWidget,
    );
    expect(find.text('Send request'), findsNothing);
  });

  testWidgets('offer to donate: a donor profile first, then the number', (
    tester,
  ) async {
    blood.all.add(sampleBloodRequest());
    await start(tester);
    await openBlood(tester);
    expect(find.text('Enam Medical College Hospital'), findsOneWidget);
    await tester.tap(find.text('Enam Medical College Hospital'));
    await tester.pumpAndSettle();
    expect(find.text('A+ blood needed'), findsOneWidget);
    expect(
      find.text('Can also receive from: A+ · A− · O+ · O−'),
      findsOneWidget,
    );

    await scrollAndTap(tester, find.text('I can donate'));
    await tester.pumpAndSettle();
    // Not a donor yet: the donor sheet first.
    await tester.tap(find.text('A+').last);
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone number'),
      '01712345678',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Offer to donate?'), findsOneWidget);
    expect(find.textContaining('go to Nusrat'), findsOneWidget);
    await tester.tap(find.text('Send my number'));
    await tester.pumpAndSettle();
    expect(blood.responses.single, ('b1', '01712345678'));
    expect(find.text('You offered to donate'), findsOneWidget);
    expect(find.text('Thank you! Nusrat can now call you.'), findsOneWidget);

    await scrollAndTap(tester, find.text("I can't any more"));
    await tester.pumpAndSettle();
    expect(find.text('I can donate'), findsOneWidget);
  });

  testWidgets('the requester sees who can help and closes it', (tester) async {
    blood.all.add(
      sampleBloodRequest(
        mine: true,
        responses: [
          BloodResponse(
            name: 'Sadia Rahman',
            bloodGroup: BloodGroup.aPos,
            phone: '01912345678',
            createdAt: DateTime(2026, 10, 27, 11),
          ),
        ],
      ),
    );
    await start(tester);
    await openBlood(tester);
    await scrollAndTap(tester, find.text('Enam Medical College Hospital').last);
    await tester.pumpAndSettle();
    expect(find.text('1 DONOR CAN HELP'), findsOneWidget);
    expect(find.text('Sadia Rahman'), findsOneWidget);
    expect(find.text('A+ · 01912345678'), findsOneWidget);
    expect(find.text('I can donate'), findsNothing, reason: 'own request');
    await scrollAndTap(tester, find.text('Got blood'));
    await tester.pumpAndSettle();
    expect(blood.all.single.status, BloodRequestStatus.fulfilled);
    expect(find.text('Glad you got help. Take care!'), findsOneWidget);
  });

  testWidgets('Today: an eligible donor sees requests for their group', (
    tester,
  ) async {
    blood
      ..donor = const Donor(bloodGroup: BloodGroup.aPos)
      ..all.addAll([
        sampleBloodRequest(),
        sampleBloodRequest(id: 'b2', group: BloodGroup.bNeg),
      ]);
    await start(tester);
    expect(find.text('A+ blood needed · Urgent'), findsOneWidget);
    expect(find.text('B− blood needed · Urgent'), findsNothing);
    await tester.tap(find.text('A+ blood needed · Urgent'));
    await tester.pumpAndSettle();
    expect(find.text('I can donate'), findsOneWidget);
  });
}
