import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

ClassSlot slot(String code, int weekday, int startMin) => ClassSlot(
  id: '$code$weekday',
  courseCode: code,
  weekday: weekday,
  startMin: startMin,
  endMin: startMin + 90,
);

ClassGroup group(List<ClassSlot> slots, {String id = 'g'}) => ClassGroup(
  id: id,
  department: 'CSE',
  batch: '61',
  semester: 'Fall 2026',
  joinCode: 'ABCDEF',
  role: GroupRole.member,
  memberCount: 2,
  slots: slots,
);

void main() {
  // Tuesday 27 October 2026, 08:25.
  final now = DateTime(2026, 10, 27, 8, 25);
  final g = group([
    slot('CSE311', DateTime.tuesday, 8 * 60 + 30), // reminder 08:20: passed
    slot('CSE313', DateTime.tuesday, 11 * 60 + 30), // 11:20 today
    slot('MAT 201', DateTime.wednesday, 9 * 60), // 08:50 tomorrow
  ]);
  const on = ReminderSettings(enabled: true);

  test('off means none', () {
    expect(
      planReminders(groups: [g], now: now, settings: const ReminderSettings()),
      isEmpty,
    );
  });

  test('upcoming classes in time order, past reminders skipped', () {
    final r = planReminders(groups: [g], now: now, settings: on, days: 2);
    expect(r.map((x) => x.item!.slot.courseCode), ['CSE313', 'MAT 201']);
    expect(r.first.at, DateTime(2026, 10, 27, 11, 20));
    expect(r.last.at, DateTime(2026, 10, 28, 8, 50));
    expect(r.map((x) => x.id), [1, 2]);
  });

  test('two weeks ahead, capped for iOS', () {
    final all = planReminders(groups: [g], now: now, settings: on);
    expect(
      all,
      hasLength(5),
      reason: '3 a week for 14 days, minus 08:30 today',
    );
    expect(
      planReminders(groups: [g], now: now, settings: on, max: 3),
      hasLength(3),
    );
  });

  test('minutes before and muted courses', () {
    final r = planReminders(
      groups: [g],
      now: now,
      settings: on.copyWith(minutesBefore: 30, muted: {'MAT201'}),
      days: 2,
    );
    expect(r.single.item!.slot.courseCode, 'CSE313');
    expect(r.single.at, DateTime(2026, 10, 27, 11));
    expect(on.copyWith(muted: {'MAT201'}).isMuted('mat 201'), isTrue);
  });

  test('the same class in two groups reminds once', () {
    final twin = group([
      slot('CSE313', DateTime.tuesday, 11 * 60 + 30),
    ], id: 'h');
    expect(
      planReminders(groups: [g, twin], now: now, settings: on, days: 1),
      hasLength(1),
    );
  });

  test('settings JSON round trip', () {
    final s = on.copyWith(minutesBefore: 15, muted: {'CSE311'}, asked: true);
    expect(ReminderSettings.fromJson(s.toJson()), s);
  });
}
