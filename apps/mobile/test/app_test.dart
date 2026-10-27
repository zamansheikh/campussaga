import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
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

    await tester.ensureVisible(find.text('সাইন আউট'));
    await tester.pumpAndSettle();
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

  testWidgets(
    'first sign-in asks for department and batch, then opens the app',
    (tester) async {
      final profile = FakeProfileRepository();
      final (repo, _) = await registerFakes(profile: profile);
      repo.googleUser = newUser; // Google gave a name, nothing else
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Set up your profile'), findsOneWidget);
      expect(find.text('Mim'), findsOneWidget, reason: 'name prefilled');

      // Saving with a missing field is refused on the spot.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('This is required.'), findsNWidgets(2));

      // Department suggestions come from classmates.
      await tester.enterText(
        find.widgetWithText(TextField, 'Department'),
        'com',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Science'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Batch'), '61');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(profile.updates.last, ('Mim', 'Computer Science', '61'));
      expect(find.text('No classes yet'), findsOneWidget);
    },
  );

  testWidgets('"Later" skips setup for now', (tester) async {
    final (repo, _) = await registerFakes();
    repo.savedUser = newUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Set up your profile'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('No classes yet'), findsOneWidget);
  });

  testWidgets('edit profile from the Profile tab', (tester) async {
    final profile = FakeProfileRepository();
    final (repo, _) = await registerFakes(profile: profile);
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('CSE · 61'), findsOneWidget);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Batch'), '62');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(profile.updates.last, ('Rafi', 'CSE', '62'));
    expect(find.text('Profile saved'), findsOneWidget);
    expect(find.textContaining('CSE · 62'), findsOneWidget);
  });

  testWidgets('delete account asks first, then signs out', (tester) async {
    final (repo, _) = await registerFakes();
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // The list builds rows lazily: scroll down to the button first.
    await tester.scrollUntilVisible(find.text('Delete account'), 200);
    await tester.ensureVisible(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.deletes, 0, reason: 'Cancel deletes nothing');

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();

    expect(repo.deletes, 1);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('an unsupported build sees only the update screen', (
    tester,
  ) async {
    final config = FakeAppConfigRepository()
      ..config = const AppConfig(
        minSupportedBuild: 9,
        storeUrls: {'android': 'https://play.google.com/x'},
      );
    final (repo, _) = await registerFakes(config: config, build: 3);
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('theme and language come back after a restart', (tester) async {
    final storage = MemorySettingsStorage();
    final (repo, _) = await registerFakes(settings: storage);
    repo.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();

    // "Restart": a fresh app with the same storage.
    await registerFakes(settings: storage);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    expect(find.text('Google দিয়ে চালিয়ে যাও'), findsOneWidget);
  });
}
