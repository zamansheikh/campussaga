import 'dart:math' as math;

import '../classes/class_models.dart' show courseKey;

/// One letter grade of a scale: [minMarks] (inclusive) up to the next
/// grade's minimum.
class Grade {
  const Grade(this.letter, this.points, this.minMarks);

  factory Grade.fromJson(Map<String, Object?> j) => Grade(
    j['letter']! as String,
    (j['points']! as num).toDouble(),
    (j['minMarks']! as num).toDouble(),
  );

  final String letter;
  final double points;
  final double minMarks;

  Map<String, Object?> toJson() => {
    'letter': letter,
    'points': points,
    'minMarks': minMarks,
  };

  @override
  bool operator ==(Object other) =>
      other is Grade &&
      other.letter == letter &&
      other.points == points &&
      other.minMarks == minMarks;

  @override
  int get hashCode => Object.hash(letter, points, minMarks);
}

/// A grading scale: letter grades with grade points and mark ranges.
class GradeScale {
  const GradeScale({required this.grades, this.custom = false});

  factory GradeScale.fromJson(Map<String, Object?> j) => GradeScale(
    custom: j['custom'] as bool? ?? true,
    grades: [
      for (final g in (j['grades'] as List? ?? const []))
        Grade.fromJson((g as Map).cast<String, Object?>()),
    ],
  );

  /// Bangladesh UGC uniform grading system (private universities; most
  /// public ones use the same 4.00 scale): marks in percent.
  static const ugc = GradeScale(
    grades: [
      Grade('A+', 4.00, 80),
      Grade('A', 3.75, 75),
      Grade('A-', 3.50, 70),
      Grade('B+', 3.25, 65),
      Grade('B', 3.00, 60),
      Grade('B-', 2.75, 55),
      Grade('C+', 2.50, 50),
      Grade('C', 2.25, 45),
      Grade('D', 2.00, 40),
      Grade('F', 0.00, 0),
    ],
  );

  /// Best first (highest points, then highest minimum marks).
  final List<Grade> grades;

  /// False for [ugc].
  final bool custom;

  double get maxPoints => grades.fold(0, (m, g) => math.max(m, g.points));

  Grade? byLetter(String? letter) {
    if (letter == null) return null;
    for (final g in grades) {
      if (g.letter == letter) return g;
    }
    return null;
  }

  /// The grade for [marks] (0–100), or null when out of range.
  Grade? forMarks(double marks) {
    if (marks.isNaN || marks < 0 || marks > 100) return null;
    Grade? best;
    for (final g in grades) {
      if (marks >= g.minMarks && (best == null || g.minMarks > best.minMarks)) {
        best = g;
      }
    }
    return best;
  }

  /// What's wrong with a custom scale (empty = valid).
  List<ScaleProblem> problems() {
    final out = <ScaleProblem>[];
    if (grades.isEmpty) return [ScaleProblem.empty];
    final letters = <String>{};
    final mins = <double>{};
    for (final g in grades) {
      if (g.letter.trim().isEmpty) out.add(ScaleProblem.letterMissing);
      if (!letters.add(g.letter.trim())) out.add(ScaleProblem.letterTwice);
      if (g.points < 0 || g.points > 5) out.add(ScaleProblem.pointsRange);
      if (g.minMarks < 0 || g.minMarks > 100) out.add(ScaleProblem.marksRange);
      if (!mins.add(g.minMarks)) out.add(ScaleProblem.marksTwice);
    }
    if (!grades.any((g) => g.minMarks == 0)) out.add(ScaleProblem.noZero);
    // A higher mark must never give fewer points.
    final byMarks = [...grades]
      ..sort((a, b) => a.minMarks.compareTo(b.minMarks));
    for (var i = 1; i < byMarks.length; i++) {
      if (byMarks[i].points < byMarks[i - 1].points) {
        out.add(ScaleProblem.order);
        break;
      }
    }
    return out.toSet().toList();
  }

  /// Sorted best first.
  GradeScale sorted() => GradeScale(
    custom: custom,
    grades: [...grades]
      ..sort((a, b) {
        final p = b.points.compareTo(a.points);
        return p != 0 ? p : b.minMarks.compareTo(a.minMarks);
      }),
  );

  Map<String, Object?> toJson() => {
    'custom': custom,
    'grades': [for (final g in grades) g.toJson()],
  };
}

enum ScaleProblem {
  empty,
  letterMissing,
  letterTwice,
  pointsRange,
  marksRange,
  marksTwice,
  noZero,
  order,
}

/// How a retaken course counts in the CGPA.
enum RetakeRule {
  /// Only the best attempt counts (the usual rule in Bangladesh).
  best,

  /// Only the latest attempt counts.
  latest,

  /// Every attempt counts.
  all;

  static RetakeRule parse(String? v) =>
      values.firstWhere((r) => r.name == v, orElse: () => best);
}

/// A course in a semester. Either [letter] or [marks] gives the grade;
/// neither = not graded yet (left out of GPA).
class CgpaCourse {
  const CgpaCourse({
    required this.id,
    this.code = '',
    this.title = '',
    this.credits = 3,
    this.letter,
    this.marks,
  });

  factory CgpaCourse.fromJson(Map<String, Object?> j) => CgpaCourse(
    id: j['id']! as String,
    code: j['code'] as String? ?? '',
    title: j['title'] as String? ?? '',
    credits: (j['credits'] as num?)?.toDouble() ?? 3,
    letter: j['letter'] as String?,
    marks: (j['marks'] as num?)?.toDouble(),
  );

  final String id;
  final String code;
  final String title;
  final double credits;
  final String? letter;
  final double? marks;

  /// The grade under [scale] (marks win over a letter).
  Grade? grade(GradeScale scale) {
    final m = marks;
    if (m != null) return scale.forMarks(m);
    return scale.byLetter(letter);
  }

  /// "CSE 311" → "CSE311"; empty code = never a retake of anything.
  String get key => courseKey(code);

  String get label => code.isNotEmpty ? code : title;

  CgpaCourse copyWith({
    String? code,
    String? title,
    double? credits,
    String? Function()? letter,
    double? Function()? marks,
  }) => CgpaCourse(
    id: id,
    code: code ?? this.code,
    title: title ?? this.title,
    credits: credits ?? this.credits,
    letter: letter != null ? letter() : this.letter,
    marks: marks != null ? marks() : this.marks,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'credits': credits,
    'letter': ?letter,
    'marks': ?marks,
  };
}

class Semester {
  const Semester({
    required this.id,
    required this.name,
    this.courses = const [],
  });

  factory Semester.fromJson(Map<String, Object?> j) => Semester(
    id: j['id']! as String,
    name: j['name'] as String? ?? '',
    courses: [
      for (final c in (j['courses'] as List? ?? const []))
        CgpaCourse.fromJson((c as Map).cast<String, Object?>()),
    ],
  );

  final String id;
  final String name;
  final List<CgpaCourse> courses;

  Semester copyWith({String? name, List<CgpaCourse>? courses}) => Semester(
    id: id,
    name: name ?? this.name,
    courses: courses ?? this.courses,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'courses': [for (final c in courses) c.toJson()],
  };
}

/// A GPA with the credits behind it. [gpa] is null with no graded credits.
class GpaResult {
  const GpaResult({
    required this.gpa,
    required this.creditsAttempted,
    required this.creditsEarned,
    required this.points,
  });

  static const none = GpaResult(
    gpa: null,
    creditsAttempted: 0,
    creditsEarned: 0,
    points: 0,
  );

  final double? gpa;

  /// Graded credits counted in the GPA (F included).
  final double creditsAttempted;

  /// Credits passed (F excluded).
  final double creditsEarned;

  /// Grade points × credits.
  final double points;
}

/// Transcript rounding: 2 decimals, halves up (3.745 → 3.75).
double roundGpa(double v) => (v * 100 + 1e-9).round() / 100;

GpaResult _gpa(Iterable<(CgpaCourse, Grade)> graded) {
  var credits = 0.0, earned = 0.0, points = 0.0;
  for (final (c, g) in graded) {
    credits += c.credits;
    points += c.credits * g.points;
    if (g.points > 0) earned += c.credits;
  }
  if (credits <= 0) return GpaResult.none;
  return GpaResult(
    gpa: roundGpa(points / credits),
    creditsAttempted: credits,
    creditsEarned: earned,
    points: points,
  );
}

/// The student's whole record: semesters in order (oldest first), the
/// scale and the retake rule. Saved on the phone.
class CgpaBook {
  const CgpaBook({
    this.semesters = const [],
    this.scale = GradeScale.ugc,
    this.retake = RetakeRule.best,
  });

  factory CgpaBook.fromJson(Map<String, Object?> j) => CgpaBook(
    semesters: [
      for (final s in (j['semesters'] as List? ?? const []))
        Semester.fromJson((s as Map).cast<String, Object?>()),
    ],
    scale: j['scale'] == null
        ? GradeScale.ugc
        : GradeScale.fromJson((j['scale']! as Map).cast<String, Object?>()),
    retake: RetakeRule.parse(j['retake'] as String?),
  );

  static const version = 1;

  final List<Semester> semesters;
  final GradeScale scale;
  final RetakeRule retake;

  bool get isEmpty => semesters.isEmpty;

  /// GPA of one semester: every course taken that semester counts.
  GpaResult semesterGpa(Semester s) => _gpa([
    for (final c in s.courses)
      if (c.grade(scale) case final g?) (c, g),
  ]);

  /// The semester's own GPA, for the latest semester with graded courses.
  GpaResult get lastSemesterGpa {
    for (final s in semesters.reversed) {
      final r = semesterGpa(s);
      if (r.gpa != null) return r;
    }
    return GpaResult.none;
  }

  /// CGPA across all semesters, credit-weighted, with retakes counted by
  /// [retake] (attempts matched by course code).
  GpaResult get cgpa {
    final graded = <(CgpaCourse, Grade, int)>[];
    for (var i = 0; i < semesters.length; i++) {
      for (final c in semesters[i].courses) {
        if (c.grade(scale) case final g?) graded.add((c, g, i));
      }
    }
    if (retake == RetakeRule.all) {
      return _gpa([for (final (c, g, _) in graded) (c, g)]);
    }
    final kept = <String, (CgpaCourse, Grade, int)>{};
    final noCode = <(CgpaCourse, Grade)>[];
    for (final e in graded) {
      final key = e.$1.key;
      if (key.isEmpty) {
        noCode.add((e.$1, e.$2));
        continue;
      }
      final prev = kept[key];
      final better = switch (retake) {
        RetakeRule.latest => prev == null || e.$3 >= prev.$3,
        // Best grade; a tie keeps the later attempt.
        _ => prev == null || e.$2.points >= prev.$2.points,
      };
      if (better) kept[key] = e;
    }
    return _gpa([...noCode, for (final (c, g, _) in kept.values) (c, g)]);
  }

  /// Courses whose earlier attempt no longer counts (for a "retaken" tag).
  Set<String> get replacedCourseIds {
    if (retake == RetakeRule.all) return const {};
    final counted = <String, (String, double, int)>{};
    final all = <String, List<String>>{};
    for (var i = 0; i < semesters.length; i++) {
      for (final c in semesters[i].courses) {
        final g = c.grade(scale);
        if (g == null || c.key.isEmpty) continue;
        all.putIfAbsent(c.key, () => []).add(c.id);
        final prev = counted[c.key];
        final better = retake == RetakeRule.latest
            ? prev == null || i >= prev.$3
            : prev == null || g.points >= prev.$2;
        if (better) counted[c.key] = (c.id, g.points, i);
      }
    }
    return {
      for (final e in all.entries)
        for (final id in e.value)
          if (id != counted[e.key]!.$1) id,
    };
  }

  CgpaBook copyWith({
    List<Semester>? semesters,
    GradeScale? scale,
    RetakeRule? retake,
  }) => CgpaBook(
    semesters: semesters ?? this.semesters,
    scale: scale ?? this.scale,
    retake: retake ?? this.retake,
  );

  Map<String, Object?> toJson() => {
    'v': version,
    'semesters': [for (final s in semesters) s.toJson()],
    'scale': scale.toJson(),
    'retake': retake.name,
  };
}

/// What [target] needs: the GPA to earn over the next [nextCredits].
sealed class TargetPlan {
  const TargetPlan();
}

/// Reachable with at least [gpa] over the next credits.
class TargetNeeds extends TargetPlan {
  const TargetNeeds(this.gpa);
  final double gpa;
}

/// Already reached: any passing result keeps it (or it is the current CGPA).
class TargetReached extends TargetPlan {
  const TargetReached();
}

/// Would need [gpa], above the scale's maximum.
class TargetOutOfReach extends TargetPlan {
  const TargetOutOfReach(this.gpa);
  final double gpa;
}

/// The GPA needed in the next [nextCredits] for the CGPA to reach
/// [target], from [current] (the book's [CgpaBook.cgpa]).
TargetPlan planTarget({
  required GpaResult current,
  required double target,
  required double nextCredits,
  double maxPoints = 4,
}) {
  if (nextCredits <= 0) return const TargetOutOfReach(double.infinity);
  final total = current.creditsAttempted + nextCredits;
  final need = (target * total - current.points) / nextCredits;
  // Round up to 2 decimals: a GPA just below wouldn't be enough.
  final shown = (need * 100 - 1e-9).ceil() / 100;
  if (shown <= 0) return const TargetReached();
  if (shown > maxPoints) return TargetOutOfReach(shown);
  return TargetNeeds(shown);
}
