import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

// Fridays at 10:00 (CSE 101) and 14:00 (MAT 201).
const fri101 = ClassSlot(
  id: 's101',
  courseCode: 'CSE 101',
  room: '402',
  weekday: DateTime.friday,
  startMin: 10 * 60,
  endMin: 11 * 60 + 30,
);
const fri201 = ClassSlot(
  id: 's201',
  courseCode: 'MAT 201',
  room: '305',
  weekday: DateTime.friday,
  startMin: 14 * 60,
  endMin: 15 * 60,
);

final wed = DateTime(2026, 10, 28);
final fri = DateTime(2026, 10, 30);
final mon = DateTime(2026, 11, 2);
final nextFri = DateTime(2026, 11, 6);

ClassGroup grp({
  String id = 'g',
  List<ClassChange> changes = const [],
  List<Assessment> assessments = const [],
  Set<String> hidden = const {},
}) => ClassGroup(
  id: id,
  department: 'CSE',
  batch: '61',
  semester: 'Fall 2026',
  joinCode: 'ABCDEF',
  role: GroupRole.member,
  memberCount: 2,
  slots: const [fri101, fri201],
  changes: changes,
  assessments: assessments,
  hiddenCourses: hidden,
);

ClassChange moveTo(DateTime to, {String slot = 's101', int start = 9 * 60}) =>
    ClassChange(
      id: 'm-$slot',
      kind: ChangeKind.moved,
      slotId: slot,
      date: fri,
      newDate: to,
      startMin: start,
      endMin: start + 90,
      room: '805',
    );

Assessment exam(
  DateTime date, {
  String id = 'a1',
  String course = 'CSE 101',
  int? start = 10 * 60,
  AssessmentKind kind = AssessmentKind.classTest,
}) => Assessment(
  id: id,
  kind: kind,
  courseCode: course,
  date: date,
  startMin: start,
  endMin: start == null ? null : start + 30,
);

const on = ReminderSettings(enabled: true);

void main() {
  group('a class moved to another day', () {
    test('earlier: off on its own day, on the new day at the new time', () {
      final g = grp(changes: [moveTo(wed)]);

      final friday = classesOn([g], fri);
      final c101 = friday.firstWhere((c) => c.slot.id == 's101');
      expect(c101.off, isTrue);
      expect(c101.movedAway, isTrue);
      expect(c101.cancelled, isFalse);
      expect(c101.moved, isFalse);
      expect(c101.movedTo, wed);
      expect(c101.startMin, 10 * 60, reason: 'shown at its usual time');
      expect(friday.firstWhere((c) => c.slot.id == 's201').off, isFalse);

      final wednesday = classesOn([g], wed);
      expect(wednesday, hasLength(1));
      final moved = wednesday.single;
      expect(moved.movedFrom, fri);
      expect(moved.off, isFalse);
      expect(moved.moved, isTrue);
      expect(moved.startMin, 9 * 60);
      expect(moved.room, '805');
      expect(moved.timeChanged, isFalse, reason: 'not a same-day time change');
    });

    test('later, and a whole week later to the same weekday', () {
      final later = grp(changes: [moveTo(mon)]);
      expect(classesOn([later], mon).single.movedFrom, fri);

      final week = grp(changes: [moveTo(nextFri, start: 16 * 60)]);
      final day = classesOn([week], nextFri);
      // Next Friday has its own CSE 101 plus the one moved there.
      expect(day.where((c) => c.slot.id == 's101'), hasLength(2));
      expect(day.last.movedFrom, fri);
      expect(day.last.startMin, 16 * 60);
    });

    test('a hidden course stays hidden on the new day', () {
      final g = grp(changes: [moveTo(wed)], hidden: {'CSE101'});
      expect(classesOn([g], wed), isEmpty);
    });

    test('the reminder follows the class', () {
      final g = grp(changes: [moveTo(wed)]);
      final r = planReminders(
        groups: [g],
        now: DateTime(2026, 10, 27, 12),
        settings: on,
        days: 4,
      );
      expect(r.map((x) => (x.item!.slot.courseCode, x.at)), [
        ('CSE 101', DateTime(2026, 10, 28, 8, 50)),
        ('MAT 201', DateTime(2026, 10, 30, 13, 50)),
      ]);
    });

    test('JSON: newDate round-trips; the same day means no move', () {
      final c = moveTo(wed);
      final back = ClassChange.fromJson(c.toJson());
      expect(back.newDate, wed);
      expect(back.movesDay, isTrue);

      final same = ClassChange.fromJson({
        ...c.toJson(),
        'newDate': '2026-10-30',
      });
      expect(same.newDate, isNull);
      expect(same.movesDay, isFalse);

      final draft = ChangeDraft.move(
        slotId: 's101',
        date: fri,
        startMin: 600,
        endMin: 690,
        newDate: wed,
      );
      expect(draft.toJson()['newDate'], '2026-10-28');
      expect(
        ChangeDraft.move(
          slotId: 's101',
          date: fri,
          startMin: 600,
          endMin: 690,
          newDate: fri,
        ).toJson().containsKey('newDate'),
        isFalse,
      );
    });
  });

  group('tests and deadlines', () {
    test('JSON round trip, also inside the group (offline copy)', () {
      final a = Assessment(
        id: 'a1',
        kind: AssessmentKind.labReport,
        courseCode: 'CSE 101',
        courseTitle: 'Programming',
        date: wed,
        startMin: 23 * 60 + 59,
        room: 'Lab 2',
        topics: 'Exp 3',
        createdById: 'u1',
        createdByName: 'Rafi',
        canEdit: true,
      );
      final json = a.toJson();
      expect(json['kind'], 'lab_report');
      final back = Assessment.fromJson(json);
      expect(back.kind, AssessmentKind.labReport);
      expect(back.startMin, 23 * 60 + 59);
      expect(back.endMin, isNull);
      expect(back.createdByName, 'Rafi');
      expect(back.canEdit, isTrue);

      final g = ClassGroup.fromJson(grp(assessments: [a]).toJson());
      expect(g.assessments.single.topics, 'Exp 3');
      expect(grp().copyWith(assessments: [a]).assessments, hasLength(1));
      expect(AssessmentKind.parse('final'), AssessmentKind.finalExam);
      expect(AssessmentKind.parse('nope'), AssessmentKind.other);
    });

    test('draft JSON: no end without a start', () {
      final d = AssessmentDraft(
        kind: AssessmentKind.assignment,
        courseCode: 'CSE 101',
        date: wed,
        endMin: 600,
      ).toJson();
      expect(d.containsKey('start'), isFalse);
      expect(d.containsKey('end'), isFalse);
    });

    test('coming up: the next 7 days, soonest first, hidden courses out', () {
      final g = grp(
        assessments: [
          exam(nextFri, id: 'later'),
          exam(fri, id: 'fri-none', start: null),
          exam(fri, id: 'fri-9', start: 9 * 60),
          exam(DateTime(2026, 11, 20), id: 'far'),
          exam(fri, id: 'hidden', course: 'MAT 201'),
          exam(DateTime(2026, 10, 27), id: 'past'),
        ],
        hidden: {'MAT201'},
      );
      final up = upcomingAssessments([g], DateTime(2026, 10, 28, 15));
      expect(up.map((x) => x.assessment.id), ['fri-9', 'fri-none']);
      expect(
        upcomingAssessments([g], wed, days: 10).map((x) => x.assessment.id),
        ['fri-9', 'fri-none', 'later'],
      );
      expect(g.assessmentsOn(fri, 'cse101'), hasLength(2));
    });

    test('reminders: 8 PM the evening before and 1 hour before', () {
      final g = grp(assessments: [exam(fri)]);
      final r = planReminders(
        groups: [g],
        now: DateTime(2026, 10, 28, 12),
        settings: on,
      );
      final forTest = r.where((x) => x.assessment != null).toList();
      expect(forTest.map((x) => (x.when, x.at)), [
        (AssessmentReminder.eveningBefore, DateTime(2026, 10, 29, 20)),
        (AssessmentReminder.soon, DateTime(2026, 10, 30, 9)),
      ]);
      expect(forTest.first.groupId, 'g');
    });

    test('no time: 9 AM that day; a past evening is skipped', () {
      final g = grp(assessments: [exam(fri, start: null)]);
      final r = planReminders(
        groups: [g],
        now: DateTime(2026, 10, 29, 21),
        settings: on,
      ).where((x) => x.assessment != null);
      expect(r.map((x) => (x.when, x.at)), [
        (AssessmentReminder.soon, DateTime(2026, 10, 30, 9)),
      ]);
    });

    test('off, muted, hidden: no reminders; shared tests only once', () {
      final shared = [
        grp(assessments: [exam(fri)]),
        grp(
          id: 'g2',
          assessments: [exam(fri, id: 'a2')],
        ),
      ];
      final now = DateTime(2026, 10, 28, 12);
      List<PlannedReminder> plan(List<ClassGroup> gs, ReminderSettings s) => [
        for (final r in planReminders(groups: gs, now: now, settings: s))
          if (r.assessment != null) r,
      ];
      expect(plan(shared, on), hasLength(2));
      expect(plan(shared, const ReminderSettings()), isEmpty);
      expect(plan(shared, on.copyWith(muted: {'CSE101'})), isEmpty);
      expect(
        plan([
          grp(assessments: [exam(fri)], hidden: {'CSE101'}),
        ], on),
        isEmpty,
      );
    });

    test('the cap keeps the soonest reminders', () {
      final g = grp(
        assessments: [
          for (var i = 0; i < 40; i++)
            exam(DateTime(2026, 10, 29 + i % 10), id: 'a$i', course: 'C$i'),
        ],
      );
      final r = planReminders(
        groups: [g],
        now: DateTime(2026, 10, 28, 12),
        settings: on,
      );
      expect(r, hasLength(60));
      for (var i = 1; i < r.length; i++) {
        expect(r[i].at.isBefore(r[i - 1].at), isFalse);
      }
    });
  });
}
