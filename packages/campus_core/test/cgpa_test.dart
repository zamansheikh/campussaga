import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

CgpaCourse c(String code, double credits, {String? g, double? marks}) =>
    CgpaCourse(
      id: '$code-$credits-$g-$marks',
      code: code,
      credits: credits,
      letter: g,
      marks: marks,
    );

void main() {
  const ugc = GradeScale.ugc;

  test('the UGC scale maps marks to grades (lower bounds inclusive)', () {
    expect(ugc.forMarks(80)!.letter, 'A+');
    expect(ugc.forMarks(79.5)!.letter, 'A');
    expect(ugc.forMarks(70)!.letter, 'A-');
    expect(ugc.forMarks(44.9)!.letter, 'D');
    expect(ugc.forMarks(39)!.letter, 'F');
    expect(ugc.forMarks(101), isNull);
    expect(ugc.byLetter('B+')!.points, 3.25);
    expect(ugc.problems(), isEmpty);
  });

  test('semester GPA is credit weighted; F counts with 0 points', () {
    final book = CgpaBook(
      semesters: [
        Semester(
          id: 's1',
          name: 'Spring',
          courses: [
            c('CSE101', 3, g: 'A+'),
            c('CSE102', 1.5, g: 'B'),
            c('MAT101', 3, g: 'F'),
            c('ENG101', 3),
          ],
        ),
      ],
    );
    final r = book.semesterGpa(book.semesters.first);
    // (3*4 + 1.5*3 + 3*0) / 7.5 = 16.5 / 7.5 = 2.2
    expect(r.gpa, 2.2);
    expect(r.creditsAttempted, 7.5, reason: 'ungraded ENG101 left out');
    expect(r.creditsEarned, 4.5, reason: 'F earns no credit');
  });

  test('rounding is half up to 2 decimals', () {
    expect(roundGpa(3.745), 3.75);
    expect(roundGpa(3.7449), 3.74);
    expect(roundGpa(2 / 3), 0.67);
  });

  test('retakes: best attempt by default, or latest, or all', () {
    final semesters = [
      Semester(
        id: 's1',
        name: '1',
        courses: [
          c('CSE 101', 3, g: 'C'),
          c('PHY101', 3, g: 'A'),
        ],
      ),
      Semester(
        id: 's2',
        name: '2',
        courses: [
          c('CSE101', 3, g: 'A'),
          c('PHY 101', 3, g: 'B'),
        ],
      ),
    ];
    final best = CgpaBook(semesters: semesters);
    // CSE101 A (3.75) and PHY101 A (3.75)
    expect(best.cgpa.gpa, 3.75);
    expect(best.cgpa.creditsAttempted, 6);
    expect(best.replacedCourseIds, hasLength(2));

    final latest = best.copyWith(retake: RetakeRule.latest);
    // CSE101 A 3.75, PHY101 B 3.00 → 3.375 → 3.38
    expect(latest.cgpa.gpa, 3.38);

    final all = best.copyWith(retake: RetakeRule.all);
    // (2.25 + 3.75 + 3.75 + 3.00) * 3 / 12 = 3.1875 → 3.19
    expect(all.cgpa.gpa, 3.19);
    expect(all.cgpa.creditsAttempted, 12);
    expect(all.replacedCourseIds, isEmpty);
  });

  test('marks give the grade through the scale', () {
    final book = CgpaBook(
      semesters: [
        Semester(
          id: 's',
          name: 's',
          courses: [
            c('X1', 3, marks: 83),
            c('X2', 3, marks: 61, g: 'A+'),
          ],
        ),
      ],
    );
    // 4.00 and 3.00 (marks win over a letter)
    expect(book.cgpa.gpa, 3.5);
    expect(book.lastSemesterGpa.gpa, 3.5);
  });

  test('a custom scale: validation and grading', () {
    const custom = GradeScale(
      custom: true,
      grades: [
        Grade('A', 4, 90),
        Grade('B', 3, 80),
        Grade('C', 2, 70),
        Grade('F', 0, 0),
      ],
    );
    expect(custom.problems(), isEmpty);
    expect(custom.forMarks(85)!.letter, 'B');
    final book = CgpaBook(
      scale: custom,
      semesters: [
        Semester(
          id: 's',
          name: 's',
          courses: [
            c('X', 3, g: 'A'),
            c('Y', 3, g: 'C'),
          ],
        ),
      ],
    );
    expect(book.cgpa.gpa, 3.0);

    expect(
      const GradeScale(grades: [Grade('A', 4, 50)]).problems(),
      contains(ScaleProblem.noZero),
    );
    expect(
      const GradeScale(grades: [Grade('A', 2, 90), Grade('B', 3, 0)])
          .problems(),
      contains(ScaleProblem.order),
      reason: 'more marks must not give fewer points',
    );
    expect(
      const GradeScale(grades: [Grade('A', 4, 0), Grade('A', 3, 0)]).problems(),
      containsAll([ScaleProblem.letterTwice, ScaleProblem.marksTwice]),
    );
    expect(
      const GradeScale(grades: [Grade('A', 6, 0)]).problems(),
      contains(ScaleProblem.pointsRange),
    );
  });

  test('target planner', () {
    final current = CgpaBook(
      semesters: [
        Semester(
          id: 's',
          name: 's',
          courses: [c('X', 30, g: 'B')],
        ),
      ],
    ).cgpa; // 3.00 over 30 credits
    // (3.5 * 45 - 90) / 15 = 4.5 → out of reach
    expect(
      planTarget(current: current, target: 3.5, nextCredits: 15),
      isA<TargetOutOfReach>(),
    );
    // (3.25 * 45 - 90) / 15 = 3.75
    final p = planTarget(current: current, target: 3.25, nextCredits: 15);
    expect((p as TargetNeeds).gpa, 3.75);
    expect(
      planTarget(current: current, target: 1, nextCredits: 15),
      isA<TargetReached>(),
    );
    // Fresh start: the target itself.
    expect(
      (planTarget(
        current: GpaResult.none,
        target: 3.4,
        nextCredits: 15,
      ) as TargetNeeds).gpa,
      3.4,
    );
  });

  test('JSON round trip', () {
    final book = CgpaBook(
      retake: RetakeRule.latest,
      scale: const GradeScale(
        custom: true,
        grades: [Grade('A', 4, 50), Grade('F', 0, 0)],
      ),
      semesters: [
        Semester(
          id: 's',
          name: 'Fall 2026',
          courses: [
            c('X', 1.5, marks: 77.5),
            c('Y', 3, g: 'A'),
          ],
        ),
      ],
    );
    final back = CgpaBook.fromJson(
      (jsonDecode(jsonEncode(book.toJson())) as Map).cast<String, Object?>(),
    );
    expect(back.retake, RetakeRule.latest);
    expect(back.scale.custom, isTrue);
    expect(back.scale.grades, book.scale.grades);
    expect(back.semesters.single.name, 'Fall 2026');
    expect(back.semesters.single.courses.first.marks, 77.5);
    expect(back.cgpa.gpa, book.cgpa.gpa);
    expect(const CgpaBook().toJson()['v'], 1);
  });
}
