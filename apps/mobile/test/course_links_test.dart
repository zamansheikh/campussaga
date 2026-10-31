import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/features/classes/presentation/widgets/course_links.dart';

import 'helpers/fakes.dart';

/// Tuesday 27 October 2026, 14:00: done for today, MAT201 is next.
final afterClasses = DateTime(2026, 10, 27, 14);

Future<FakeClassGroupRepository> signedIn(
  WidgetTester tester,
  ClassGroup group,
) async {
  usePhoneScreen(tester);
  final classes = FakeClassGroupRepository()..mine.add(group);
  final (repo, _) = await registerFakes(classes: classes);
  repo.savedUser = testUser;
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  return classes;
}

void main() {
  setUp(() => appNow = () => afterClasses);
  tearDown(() => appNow = DateTime.now);

  testWidgets('the CR adds a course chat group and Classroom code', (
    tester,
  ) async {
    final classes = await signedIn(tester, sampleGroup(role: GroupRole.cr));
    await scrollAndTap(tester, find.text('MAT201'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add chat group, Classroom code…'));
    await tester.pumpAndSettle();
    expect(
      find.text('All optional. Everyone in the group sees them.'),
      findsOneWidget,
    );
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Class chat group'),
      'not a link',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Classroom code'),
      'ab3x9kq',
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a web link, like chat.whatsapp.com/…'),
      findsOneWidget,
    );
    expect(classes.mine.single.courses, isEmpty, reason: 'not sent');

    await tester.enterText(
      find.widgetWithText(TextField, 'Class chat group'),
      'chat.whatsapp.com/AbC123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Notes'),
      'Office hours: Sun 2-3 PM',
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    final info = classes.mine.single.courseInfo('MAT 201');
    expect(info.chatLink, 'https://chat.whatsapp.com/AbC123');
    expect(info.classroomCode, 'ab3x9kq');
    expect(info.notes, 'Office hours: Sun 2-3 PM');
    expect(find.textContaining('Saved.'), findsOneWidget);
  });

  testWidgets('classmates see the links; tapping the code copies it', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await signedIn(
      tester,
      sampleGroup().copyWith(
        courses: {
          'MAT201': const CourseInfo(
            chatLink: 'https://m.me/j/abc',
            classroomCode: 'ab3x9kq',
            teacherEmail: 'sir@ju.ac.bd',
          ),
        },
      ),
    );
    await scrollAndTap(tester, find.text('MAT201'));
    await tester.pumpAndSettle();
    expect(find.text('COURSE LINKS'), findsOneWidget);
    expect(find.text('Messenger'), findsOneWidget);
    expect(find.text('sir@ju.ac.bd'), findsOneWidget);
    expect(find.text('Edit'), findsNothing, reason: 'members only read');
    await tester.tap(find.text('Code: ab3x9kq · tap to copy'));
    await tester.pumpAndSettle();
    expect(copied, ['ab3x9kq']);
    expect(find.text('Classroom code copied'), findsOneWidget);
  });

  test('chat apps by name', () {
    expect(chatAppName('https://chat.whatsapp.com/x'), 'WhatsApp');
    expect(chatAppName('https://m.me/j/x'), 'Messenger');
    expect(chatAppName('https://t.me/joinchat/x'), 'Telegram');
    expect(chatAppName('https://discord.gg/x'), 'Discord');
    expect(chatAppName('https://www.example.com/x'), 'example.com');
  });
}
