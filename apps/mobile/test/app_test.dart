import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('signed out: shows sign-in, Google sign-in opens the app', (
    tester,
  ) async {
    final (repo, _) = await registerFakes();
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(repo.lastGoogleToken, 'firebase-id-token');
    expect(find.text('No classes yet'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a personal Google account shows why it was refused', (
    tester,
  ) async {
    final (repo, _) = await registerFakes();
    repo.googleFailure = const RejectedFailure(
      code: 'UNIVERSITY_EMAIL_REQUIRED',
    );
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining("This isn't a university account"), findsOne);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('signed in: profile shows the account, Bangla, sign out', (
    tester,
  ) async {
    final (repo, _) = await registerFakes();
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Rafi'), findsOneWidget);
    expect(find.textContaining('Demo University'), findsOneWidget);

    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(find.text('প্রোফাইল'), findsWidgets);
    expect(find.textContaining('ডেমো বিশ্ববিদ্যালয়'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('সাইন আউট'), 100);
    await tester.tap(find.text('সাইন আউট'));
    await tester.pumpAndSettle();
    expect(repo.signOuts, 1);
    expect(find.text('Google দিয়ে চালিয়ে যাও'), findsOneWidget);
  });

  testWidgets('email code: email -> code -> signed in', (tester) async {
    final (repo, _) = await registerFakes();
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use university email instead'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your university email'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rafi@diu.edu.bd');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('We sent a 6-digit code to rafi@diu.edu.bd'), findsOne);
    expect(find.text('Demo University'), findsOneWidget);
    expect(find.textContaining('Resend code in 1:00'), findsOneWidget);

    // The real one-second countdown runs.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Resend code in 0:58'), findsOneWidget);

    // A wrong code shows how many tries are left.
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text("That code isn't right. 4 tries left."), findsOneWidget);

    // Typing all 6 digits submits on its own.
    await tester.enterText(find.byType(TextField), '123456');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();

    expect(repo.verified.last, ('rafi@diu.edu.bd', '123456'));
    expect(find.text('No classes yet'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('email code: a non-university email is explained', (
    tester,
  ) async {
    final (repo, _) = await registerFakes();
    repo.requestFailure = const RejectedFailure(
      code: 'UNIVERSITY_EMAIL_REQUIRED',
    );
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use university email instead'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'me@gmail.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("This email isn't from a supported university"),
      findsOneWidget,
    );
    expect(find.text('Enter your university email'), findsOneWidget);
  });
}
