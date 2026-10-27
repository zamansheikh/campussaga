import 'package:campussaga/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Today with the bottom navigation', (tester) async {
    await pumpApp(tester);

    expect(find.text('No classes yet'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switching language to Bangla updates the UI', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();

    expect(find.text('প্রোফাইল'), findsWidgets);
  });
}
