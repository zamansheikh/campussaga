import 'package:campussaga/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('Gmail: choose the university, use the app as not verified, '
      'then verify with a university email', (tester) async {
    usePhoneScreen(tester);
    final profile = FakeProfileRepository();
    final (repo, _) = await registerFakes(profile: profile);
    repo.googleUser = gmailUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Set up your profile'), findsOneWidget);
    expect(find.text('Choose your university'), findsOneWidget);
    expect(find.text('Later'), findsNothing, reason: 'groups need it');

    // Pick it from the list (search works on English and Bangla names).
    await tester.tap(find.text('Choose your university'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'engineering');
    await tester.pumpAndSettle();
    expect(find.text('Demo University'), findsNothing);
    await tester.tap(
      find.text('Bangladesh University of Engineering and Technology'),
    );
    await tester.pumpAndSettle();
    expect(profile.edited?.university?.slug, 'buet');
    expect(find.text('Later'), findsOneWidget);

    // The rest of the profile, then the app.
    await tester.enterText(find.widgetWithText(TextField, 'Department'), 'CSE');
    await tester.enterText(find.widgetWithText(TextField, 'Batch'), '19');
    await scrollAndTap(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Not verified'), findsOneWidget);

    // Verify later with a university email.
    await scrollAndTap(tester, find.text('Verify with university email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'me@gmail.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.textContaining("isn't from a supported university"), findsOne);

    await tester.enterText(find.byType(TextField), 'tanvir@cse.demo.ac.bd');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(
      find.text('We sent a 6-digit code to tanvir@cse.demo.ac.bd'),
      findsOne,
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(find.text("You're now a verified student"), findsOneWidget);
    expect(find.text('Verified student'), findsOneWidget);
    expect(find.text('Not verified'), findsNothing);
    expect(find.text('Verify with university email'), findsNothing);
  });

  testWidgets('a verified student moves to a university without its email', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final profile = FakeProfileRepository()..me = testUser;
    final (repo, _) = await registerFakes(profile: profile);
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Verified student'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('With my new university email'), findsOneWidget);
    await tester.tap(find.text('Without a university email'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Bangladesh University of Engineering and Technology'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Move to Bangladesh University of Engineering and Technology?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();

    expect(find.text('University changed'), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);
    expect(profile.edited?.university?.slug, 'buet');
  });

  testWidgets('the wrong Google account: start over from profile setup', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final (repo, _) = await registerFakes();
    repo.googleUser = gmailUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as ${gmailUser.email}'), findsOneWidget);
    await scrollAndTap(tester, find.text('Use a different account'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
