import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

ClassSlot slot(String code, int weekday, String start, String end) => ClassSlot(
  id: code,
  courseCode: code,
  weekday: weekday,
  startMin: Clock.parse(start),
  endMin: Clock.parse(end),
);

void main() {
  test('clock', () {
    expect(Clock.parse('08:30'), 510);
    expect(Clock.format(510), '08:30');
    expect(Clock.format(0), '00:00');
  });

  test('group JSON round trip', () {
    final json = {
      'id': 'g1',
      'department': 'CSE',
      'batch': '61',
      'section': 'A',
      'semester': 'Fall 2026',
      'joinCode': 'KQWZRT',
      'role': 'cr',
      'memberCount': 42,
      'updatedAt': '2026-10-27T10:00:00Z',
      'slots': [
        {
          'id': 's1',
          'courseCode': 'CSE311',
          'courseTitle': 'Database Systems',
          'teacher': 'Dr. Rahman',
          'room': '504',
          'weekday': 2,
          'start': '08:30',
          'end': '10:00',
          'kind': 'lab',
        },
      ],
    };
    final g = ClassGroup.fromJson(json);
    expect(g.isCr, isTrue);
    expect(g.title, 'CSE 61 · A');
    expect(g.slots.single.kind, ClassKind.lab);
    expect(g.slots.single.startMin, 510);
    final back = ClassGroup.fromJson(g.toJson());
    expect(back.toJson(), g.toJson());
  });

  test('classesOn merges groups and sorts by time', () {
    final a = ClassGroup(
      id: 'a',
      department: 'CSE',
      batch: '61',
      semester: 'Fall',
      joinCode: 'AAAAAA',
      role: GroupRole.member,
      memberCount: 1,
      slots: [
        slot('CSE313', 2, '11:30', '13:00'),
        slot('CSE311', 3, '08:30', '10:00'),
      ],
    );
    final b = a.copyWith(slots: [slot('MAT201', 2, '09:00', '10:00')]);
    final tuesday = DateTime(2026, 10, 27, 15, 45);
    final list = classesOn([a, b], tuesday);
    expect(list.map((c) => c.slot.courseCode), ['MAT201', 'CSE313']);
    expect(list.first.startsAt, DateTime(2026, 10, 27, 9));
    expect(classesOn([a, b], DateTime(2026, 10, 30)), isEmpty);
  });
}
