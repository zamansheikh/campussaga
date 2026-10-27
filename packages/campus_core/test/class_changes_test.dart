import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

const slot311 = ClassSlot(
  id: 's311',
  courseCode: 'CSE311',
  room: '504',
  weekday: DateTime.wednesday,
  startMin: 9 * 60,
  endMin: 10 * 60 + 30,
);
const slot313 = ClassSlot(
  id: 's313',
  courseCode: 'CSE313',
  room: '602',
  weekday: DateTime.wednesday,
  startMin: 11 * 60,
  endMin: 12 * 60 + 30,
);

ClassGroup group(List<ClassChange> changes) => ClassGroup(
  id: 'g',
  department: 'CSE',
  batch: '61',
  semester: 'Fall 2026',
  joinCode: 'ABCDEF',
  role: GroupRole.member,
  memberCount: 2,
  slots: const [slot311, slot313],
  changes: changes,
);

final wed = DateTime(2026, 10, 28);
final nextWed = DateTime(2026, 11, 4);

void main() {
  final changes = [
    ClassChange(
      id: 'c1',
      kind: ChangeKind.cancelled,
      slotId: 's311',
      date: wed,
    ),
    ClassChange(
      id: 'c2',
      kind: ChangeKind.moved,
      slotId: 's313',
      date: wed,
      startMin: 8 * 60,
      endMin: 9 * 60 + 30,
      room: '805',
    ),
    ClassChange(
      id: 'c3',
      kind: ChangeKind.extra,
      date: wed,
      courseCode: 'MAT201',
      startMin: 14 * 60,
      endMin: 15 * 60,
    ),
  ];

  test('changes apply on their date only', () {
    final day = classesOn([group(changes)], wed);
    expect(day.map((c) => c.slot.courseCode), ['CSE313', 'CSE311', 'MAT201']);
    final moved = day[0];
    expect(moved.moved, isTrue);
    expect(moved.startsAt, DateTime(2026, 10, 28, 8));
    expect(moved.room, '805');
    expect(moved.timeChanged && moved.roomChanged, isTrue);
    expect(day[1].cancelled, isTrue, reason: 'kept, marked');
    expect(day[2].extra, isTrue);
    expect(day[2].slot.weekday, DateTime.wednesday);

    final later = classesOn([group(changes)], nextWed);
    expect(later.map((c) => c.change), [null, null]);
    expect(later.first.room, '504');
  });

  test('moved with the room unchanged keeps the room', () {
    final g = group([
      ClassChange(
        id: 'c',
        kind: ChangeKind.moved,
        slotId: 's311',
        date: wed,
        startMin: 10 * 60,
        endMin: 11 * 60,
      ),
    ]);
    final c = classesOn([g], wed).first;
    expect(c.room, '504');
    expect(c.roomChanged, isFalse);
  });

  test('reminders skip cancelled classes and follow moved ones', () {
    final r = planReminders(
      groups: [group(changes)],
      now: DateTime(2026, 10, 27, 20),
      settings: const ReminderSettings(enabled: true),
      days: 2,
    );
    expect(r.map((x) => (x.item.slot.courseCode, x.at)), [
      ('CSE313', DateTime(2026, 10, 28, 7, 50)),
      ('MAT201', DateTime(2026, 10, 28, 13, 50)),
    ]);
  });

  test('announcements: JSON and order', () {
    final old = Announcement(
      id: 'a',
      body: 'old',
      createdAt: DateTime(2026, 10, 1),
    );
    final newer = Announcement(
      id: 'b',
      body: 'new',
      createdAt: DateTime(2026, 10, 2),
    );
    final pinned = old.copyWith(pinned: true);
    expect(sortAnnouncements([old, newer]).map((a) => a.id), ['b', 'a']);
    expect(sortAnnouncements([newer, pinned]).map((a) => a.id), ['a', 'b']);
    final g = group(const []).copyWith(announcements: [newer]);
    final back = ClassGroup.fromJson(g.toJson());
    expect(back.announcements.single.body, 'new');
    expect(back.announcements.single.createdAt, newer.createdAt);
    expect(back.copyWith(slots: const []).announcements, hasLength(1));
  });

  test('copyWith keeps the changes', () {
    expect(group(changes).copyWith(slots: const []).changes, hasLength(3));
  });

  test('JSON round trip and drafts', () {
    final g = group(changes);
    final back = ClassGroup.fromJson(g.toJson());
    expect(back.toJson(), g.toJson());
    // Saved offline: changes must survive the round trip.
    expect(back.changes.map((c) => (c.kind, c.date, c.room, c.startMin)), [
      for (final c in changes) (c.kind, c.date, c.room, c.startMin),
    ]);
    expect(
      ChangeDraft.cancel(slotId: 's311', date: wed, note: 'sick').toJson(),
      containsPair('date', '2026-10-28'),
    );
    final move = ChangeDraft.move(
      slotId: 's313',
      date: wed,
      startMin: 480,
      endMin: 570,
    ).toJson();
    expect(move['kind'], 'moved');
    expect(move['start'], '08:00');
    expect(
      ChangeDraft.extra(
        date: wed,
        courseCode: 'X',
        startMin: 1,
        endMin: 2,
      ).toJson(),
      isNot(contains('slotId')),
    );
  });
}
