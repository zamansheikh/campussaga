import 'package:campussaga/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('Explore lists the tools and what is coming', (tester) async {
    usePhoneScreen(tester);
    final (auth, _) = await registerFakes();
    auth.savedUser = testUser;
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Class groups'), findsOneWidget);
    expect(find.text('Class reminders'), findsOneWidget);
    expect(find.text('Bus routes'), findsOneWidget);
    expect(find.text('Teacher evaluations'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Visit other campuses'), 200);
    expect(find.text('University rankings'), findsOneWidget);
    expect(find.text('Coming soon'), findsWidgets);

    // A coming feature explains itself.
    await scrollAndTap(tester, find.text('Bus routes'));
    await tester.pumpAndSettle();
    expect(
      find.text("We're building this. It will arrive in a future update."),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    // A tool opens its page.
    await tester.tap(find.text('Class reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Remind me before each class'), findsOneWidget);
  });
}
