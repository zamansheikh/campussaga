import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/features/verification/presentation/pages/vouch_page.dart';

import 'campus_fakes.dart';
import 'helpers/fakes.dart';

const notVerifiedUser = UserProfile(
  id: 'u9',
  email: 'tanvir@gmail.com',
  university: University(
    id: 'uni1',
    slug: 'demo-university',
    name: 'Demo University',
  ),
  role: 'student',
  displayName: 'Tanvir Ahmed',
  department: 'CSE',
  batch: '61',
);

void main() {
  setUp(() => appNow = () => DateTime(2026, 10, 27, 12));
  tearDown(() => appNow = DateTime.now);

  Future<void> start(
    WidgetTester tester, {
    UserProfile user = notVerifiedUser,
    FakeVerificationRepository? verification,
    FakeClassGroupRepository? classes,
  }) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes(
      verification: verification,
      classes: classes,
    );
    auth.savedUser = user;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  group('Get verified', () {
    testWidgets('banner on Today opens the three ways', (tester) async {
      await start(tester);
      expect(find.text('Get verified at your university'), findsOneWidget);
      await tester.tap(find.text('Get verified at your university'));
      await tester.pumpAndSettle();

      expect(find.text('Use your university email'), findsWidgets);
      expect(find.text('Rafi, CR of CSE 61 · A'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget, reason: 'progress');
      expect(find.text('Nusrat'), findsOneWidget, reason: 'who vouched');
      expect(find.text('Share link'), findsOneWidget);
    });

    testWidgets('no email row when the university has no domains', (
      tester,
    ) async {
      final v = FakeVerificationRepository()
        ..mineData = const MyVerification(
          verified: false,
          emailPossible: false,
          code: 'abc12345',
          link: 'https://varsitykotha.com/v/abc12345',
        );
      await start(tester, verification: v);
      await tester.tap(find.text('Get verified at your university'));
      await tester.pumpAndSettle();
      expect(find.text('Use your university email'), findsNothing);
      expect(
        find.textContaining('You are not in a class group yet'),
        findsOneWidget,
      );
      expect(find.text('0 of 2'), findsOneWidget);
    });

    testWidgets('Profile has the banner; verified students do not', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Get verified at your university'), findsOneWidget);
    });

    testWidgets('verified: a success state, and no banner', (tester) async {
      await start(tester, user: testUser);
      expect(find.text('Get verified at your university'), findsNothing);
    });

    testWidgets('verified by classmates is told so', (tester) async {
      final v = FakeVerificationRepository()
        ..mineData = const MyVerification(
          verified: true,
          via: VerifiedVia.vouch,
        );
      await start(tester, verification: v);
      await tester.tap(find.text('Get verified at your university'));
      await tester.pumpAndSettle();
      expect(find.text("You're verified"), findsOneWidget);
      expect(find.text('Vouched for by your classmates.'), findsOneWidget);
    });
  });

  group('Vouch page', () {
    Future<FakeVerificationRepository> pumpVouch(
      WidgetTester tester,
      VouchCard card, {
      String? error,
    }) async {
      usePhoneScreen(tester);
      final v = FakeVerificationRepository()
        ..card = card
        ..vouchError = error;
      await registerFakes(verification: v);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: CsTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VouchPage(code: 'abc12345'),
        ),
      );
      await tester.pumpAndSettle();
      return v;
    }

    testWidgets('the card, then Thanks and finally verified', (tester) async {
      final v = await pumpVouch(tester, sampleVouchCard());
      expect(find.text('Tanvir Ahmed'), findsOneWidget);
      expect(find.text('CSE · 61'), findsOneWidget);
      expect(find.text('Demo University'), findsOneWidget);
      final button = find.text('I know them, they study at Demo University');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(v.vouchedCodes, ['abc12345']);
      expect(find.text('Thanks! 1 more classmate needed'), findsOneWidget);
      expect(button, findsNothing);
    });

    testWidgets('the second vouch verifies them', (tester) async {
      await pumpVouch(tester, sampleVouchCard(vouches: 1));
      await tester.tap(find.text('I know them, they study at Demo University'));
      await tester.pumpAndSettle();
      expect(find.text('Tanvir Ahmed is verified'), findsOneWidget);
    });

    testWidgets('every reason is explained in plain words', (tester) async {
      const expected = {
        VouchReason.self: 'This is your own link.',
        VouchReason.notVerified: 'You need to be verified yourself',
        VouchReason.otherUniversity: 'only vouch for students of your own',
        VouchReason.blocked: "You can't vouch for others right now.",
        VouchReason.limit: "You've vouched a lot lately",
        VouchReason.alreadyVerified: 'Tanvir Ahmed is already verified.',
      };
      for (final e in expected.entries) {
        if (e.key == VouchReason.alreadyVerified) {
          await pumpVouch(
            tester,
            sampleVouchCard(canVouch: false, verified: true),
          );
        } else {
          await pumpVouch(
            tester,
            sampleVouchCard(canVouch: false, reason: e.key),
          );
        }
        expect(
          find.textContaining(e.value),
          findsOneWidget,
          reason: '${e.key}',
        );
        expect(
          find.text('I know them, they study at Demo University'),
          findsNothing,
        );
      }
    });

    testWidgets('an error answer is explained too', (tester) async {
      await pumpVouch(tester, sampleVouchCard(), error: 'VOUCH_LIMIT');
      await tester.tap(find.text('I know them, they study at Demo University'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("You've vouched a lot lately"),
        findsOneWidget,
      );
    });

    testWidgets('a link that is gone says so', (tester) async {
      usePhoneScreen(tester);
      final v = FakeVerificationRepository()
        ..failure = const NotFoundFailure(code: 'VOUCH_NOT_FOUND');
      await registerFakes(verification: v);
      await tester.pumpWidget(
        MaterialApp(
          theme: CsTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VouchPage(code: 'nope'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("This link isn't valid anymore."), findsOneWidget);
    });
  });

  group('CR confirm', () {
    testWidgets('Confirm asks, then the member is verified', (tester) async {
      final classes = FakeClassGroupRepository()
        ..mine.add(sampleGroup(role: GroupRole.cr))
        ..membersOf['g-cse'] = const [
          GroupMember(
            userId: 'u1',
            name: 'Rafi',
            role: GroupRole.cr,
            isMe: true,
          ),
          GroupMember(
            userId: 'u3',
            name: 'Mim Akter',
            role: GroupRole.member,
            verified: false,
          ),
        ];
      final v = FakeVerificationRepository();
      await start(tester, user: testUser, verification: v, classes: classes);
      await scrollAndTap(tester, find.text('CSE 61 · A'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.text('Members'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget, reason: 'only Mim');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
        find.text('Only confirm classmates you know are in your section.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(v.confirmed, [('g-cse', 'u3')]);
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Not verified'), findsNothing);
      expect(find.text('Mim Akter is verified now'), findsOneWidget);
    });

    testWidgets('a confirm error is explained', (tester) async {
      final classes = FakeClassGroupRepository()
        ..mine.add(sampleGroup(role: GroupRole.cr))
        ..membersOf['g-cse'] = const [
          GroupMember(
            userId: 'u3',
            name: 'Mim Akter',
            role: GroupRole.member,
            verified: false,
          ),
        ];
      final v = FakeVerificationRepository()..vouchError = 'CONFIRM_LIMIT';
      await start(tester, user: testUser, verification: v, classes: classes);
      await scrollAndTap(tester, find.text('CSE 61 · A'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.text('Members'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining("You've confirmed a lot"), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget, reason: 'still waiting');
    });
  });

  group('Request your university', () {
    testWidgets('an unknown domain offers the form, which sends it', (
      tester,
    ) async {
      usePhoneScreen(tester);
      final v = FakeVerificationRepository();
      final (repo, _) = await registerFakes(verification: v);
      repo.requestFailure = const RejectedFailure(
        code: 'UNIVERSITY_EMAIL_REQUIRED',
      );
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use university email instead'));
      await tester.pumpAndSettle();
      expect(find.text('Request your university'), findsNothing);

      await tester.enterText(find.byType(TextField), 'me@newuni.edu.bd');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request your university'));
      await tester.pumpAndSettle();

      // Empty: asked for a name.
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(v.domainRequests, isEmpty);
      expect(find.textContaining('Type your university'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'University name'),
        'New Era University',
      );
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(v.domainRequests.single, (
        'me@newuni.edu.bd',
        null,
        'New Era University',
      ));
      expect(find.text("We'll add it soon"), findsOneWidget);
    });
  });
}
