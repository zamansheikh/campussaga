import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:varsitykotha/features/widget/home_widget.dart';
import 'package:varsitykotha/features/widget/widget_data.dart';

// Tuesday 27 October 2026, 08:05.
final now = DateTime(2026, 10, 27, 8, 5);

ClassGroup group({
  List<ClassChange> changes = const [],
  List<Assessment> tests = const [],
}) => ClassGroup(
  id: 'g1',
  department: 'CSE',
  batch: '61',
  semester: 'Fall 2026',
  joinCode: 'ABCDEF',
  role: GroupRole.member,
  memberCount: 30,
  hiddenCourses: {courseKey('ENG101')},
  slots: const [
    ClassSlot(
      id: 's101',
      courseCode: 'CSE101',
      room: '301',
      weekday: 2,
      startMin: 540,
      endMin: 630,
    ), // Tue 9:00
    ClassSlot(
      id: 's102',
      courseCode: 'CSE102',
      weekday: 5,
      startMin: 600,
      endMin: 690,
    ), // Fri 10:00
    ClassSlot(
      id: 'seng',
      courseCode: 'ENG101',
      weekday: 3,
      startMin: 480,
      endMin: 540,
    ), // Wed, hidden
  ],
  changes: changes,
  assessments: tests,
);

Map<String, Object?> data(
  List<ClassGroup> routine, {
  DateTime? at,
  String lang = 'en',
}) => jsonDecode(
  buildWidgetJson(routine: routine, now: at ?? now, lang: lang, signedIn: true),
) as Map<String, Object?>;

List<Map<String, Object?>> list(Map<String, Object?> d, String key) =>
    (d[key]! as List<Object?>).cast<Map<String, Object?>>();

/// intl puts a narrow no-break space before AM/PM.
String? n(Object? s) => (s as String?)?.replaceAll('\u202f', ' ');

int ms(int y, int m, int d, int h, int min) =>
    DateTime(y, m, d, h, min).millisecondsSinceEpoch;

void main() {
  setUpAll(initializeDateFormatting);

  test('classes: next two weeks, earliest first, with what changed', () {
    final d = data([
      group(
        changes: [
          // Friday 30 Oct moved to Wednesday 28 Oct, 11:00, room 805.
          ClassChange(
            id: 'c1',
            kind: ChangeKind.moved,
            slotId: 's102',
            date: DateTime(2026, 10, 30),
            newDate: DateTime(2026, 10, 28),
            startMin: 660,
            endMin: 750,
            room: '805',
          ),
          // Tuesday 3 Nov cancelled.
          ClassChange(
            id: 'c2',
            kind: ChangeKind.cancelled,
            slotId: 's101',
            date: DateTime(2026, 11, 3),
          ),
          // Extra class Thursday 29 Oct.
          ClassChange(
            id: 'c3',
            kind: ChangeKind.extra,
            date: DateTime(2026, 10, 29),
            courseCode: 'MAT201',
            startMin: 840,
            endMin: 900,
          ),
        ],
      ),
    ]);
    expect(d['signedIn'], true);
    final classes = list(d, 'classes');
    expect(
      classes.map(
        (c) =>
            '${c['course']}@${DateTime.fromMillisecondsSinceEpoch(c['start']! as int)}',
      ),
      [
        'CSE101@2026-10-27 09:00:00.000',
        'CSE102@2026-10-28 11:00:00.000', // moved here (not on Friday the 30th)
        'MAT201@2026-10-29 14:00:00.000',
        'CSE102@2026-11-06 10:00:00.000', // Tue 3 Nov cancelled; nothing from 10 Nov
      ],
    );
    expect(n(classes[0]['time']), '9:00 AM – 10:30 AM');
    expect(classes[0]['room'], '301');
    expect(classes[0]['date'], 'Tue 27 Oct');
    expect(classes[0]['badge'], '');
    expect(classes[0]['end'], ms(2026, 10, 27, 10, 30));
    expect(classes[1]['badge'], 'Moved from Fri 30 Oct');
    expect(n(classes[1]['time']), '11:00 AM – 12:30 PM');
    expect(classes[1]['room'], '805');
    expect(classes[2]['badge'], 'Extra class');
    expect(n(classes[2]['time']), '2:00 PM – 3:00 PM');
    expect(classes[2]['room'], '', reason: 'no room');
  });

  test('a class that already ended today is left out', () {
    final classes = list(
      data([group()], at: DateTime(2026, 10, 27, 10, 45)),
      'classes',
    );
    expect(classes.first['course'], 'CSE102');
  });

  test('tests and deadlines: window, hidden courses, no-time ones', () {
    final d = data([
      group(
        tests: [
          Assessment(
            id: 'a2',
            kind: AssessmentKind.assignment,
            courseCode: 'CSE102',
            date: DateTime(2026, 10, 30),
          ),
          Assessment(
            id: 'a1',
            kind: AssessmentKind.classTest,
            courseCode: 'CSE101',
            date: DateTime(2026, 10, 28),
            startMin: 600,
            endMin: 630,
            room: '402',
          ),
          Assessment(
            id: 'a3',
            kind: AssessmentKind.quiz,
            courseCode: 'ENG101',
            date: DateTime(2026, 10, 28),
          ),
          Assessment(
            id: 'a4',
            kind: AssessmentKind.midterm,
            courseCode: 'CSE101',
            date: DateTime(2026, 11, 20),
          ),
          Assessment(
            id: 'a5',
            kind: AssessmentKind.labReport,
            courseCode: 'CSE102',
            date: DateTime(2026, 10, 31),
            startMin: 23 * 60 + 59,
          ),
        ],
      ),
    ]);
    final tests = list(d, 'tests');
    expect(tests.map((t) => t['title']), [
      'Class test · CSE101',
      'Assignment · CSE102',
      'Lab report · CSE102',
    ], reason: 'hidden ENG101 and the mid beyond two weeks are left out');
    expect(n(tests[0]['time']), '10:00 AM – 10:30 AM');
    expect(tests[0]['room'], '402');
    expect(tests[0]['at'], ms(2026, 10, 28, 10, 0));
    expect(tests[0]['until'], ms(2026, 10, 28, 10, 30));
    expect(tests[0]['date'], 'Wed 28 Oct');
    expect(
      n(tests[1]['time']),
      '',
      reason: 'no time: due by the end of the day',
    );
    expect(tests[1]['at'], ms(2026, 10, 30, 0, 0));
    expect(tests[1]['until'], ms(2026, 10, 31, 0, 0));
    expect(n(tests[2]['time']), 'Due 11:59 PM');
    expect(
      tests[2]['until'],
      ms(2026, 11, 1, 0, 59),
      reason: 'start + 1 hour without an end',
    );
  });

  test('Bangla: labels, kinds and Bangla digits', () {
    final d = data([
      group(
        tests: [
          Assessment(
            id: 'a1',
            kind: AssessmentKind.classTest,
            courseCode: 'CSE101',
            date: DateTime(2026, 10, 28),
            startMin: 600,
          ),
        ],
      ),
    ], lang: 'bn');
    expect(d['lang'], 'bn');
    final labels = (d['labels']! as Map<String, Object?>);
    expect(labels['now'], 'এখন');
    expect(labels['inMin'], '{m} মিনিট পর');
    final c = list(d, 'classes').first;
    expect(c['time'] as String, contains('৯:০০'));
    expect(c['room'], '301');
    expect(list(d, 'tests').first['title'], 'ক্লাস টেস্ট · CSE101');
  });

  test('signed out: only the sign-in hint', () {
    final d = jsonDecode(
      buildWidgetJson(
        routine: [group()],
        now: now,
        lang: 'en',
        signedIn: false,
      ),
    );
    expect(d, {
      'v': 2,
      'lang': 'en',
      'signedIn': false,
      'labels': {'signedOut': 'Sign in to see your classes'},
    });
  });

  test('saves only when something changed', () async {
    final bridge = _MemoryBridge();
    final sync = HomeWidgetSync(bridge: bridge);
    await sync.save(routine: [group()], signedIn: true, lang: 'en');
    await sync.save(routine: [group()], signedIn: true, lang: 'en');
    expect(bridge.saved, hasLength(1));
    await sync.save(routine: [group()], signedIn: true, lang: 'bn');
    expect(bridge.saved, hasLength(2));
  });
}

class _MemoryBridge implements WidgetBridge {
  final saved = <String>[];

  @override
  Future<void> save(String json) async => saved.add(json);
}
