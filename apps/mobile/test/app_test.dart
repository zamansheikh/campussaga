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
}
