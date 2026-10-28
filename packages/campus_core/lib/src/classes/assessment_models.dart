import 'class_models.dart';

/// What kind of test or deadline. [wire] is the API value.
enum AssessmentKind {
  classTest('class_test'),
  quiz('quiz'),
  assignment('assignment'),
  labReport('lab_report'),
  presentation('presentation'),
  midterm('midterm'),
  finalExam('final'),
  other('other');

  const AssessmentKind(this.wire);

  final String wire;

  /// Handed in by a time rather than sat at one: the time is a due time.
  bool get isDeadline => this == assignment || this == labReport;

  static AssessmentKind parse(String? v) =>
      values.firstWhere((k) => k.wire == v, orElse: () => other);
}

/// A class test, quiz, exam or deadline of one course in a class group.
/// Any member can add one; the person who added it and the CRs can change
/// or delete it ([canEdit]).
class Assessment {
  const Assessment({
    required this.id,
    required this.kind,
    required this.courseCode,
    this.courseTitle = '',
    required this.date,
    this.startMin,
    this.endMin,
    this.room = '',
    this.topics = '',
    this.createdById,
    this.createdByName,
    this.canEdit = false,
  });

  factory Assessment.fromJson(Map<String, Object?> json) {
    final start = json['start'] as String?;
    final end = json['end'] as String?;
    final by = json['createdBy'] as Map<String, Object?>?;
    return Assessment(
      id: json['id']! as String,
      kind: AssessmentKind.parse(json['kind'] as String?),
      courseCode: json['courseCode']! as String,
      courseTitle: json['courseTitle'] as String? ?? '',
      date: parseDate(json['date']! as String),
      startMin: start == null || start.isEmpty ? null : Clock.parse(start),
      endMin: end == null || end.isEmpty ? null : Clock.parse(end),
      room: json['room'] as String? ?? '',
      topics: json['topics'] as String? ?? '',
      createdById: by?['id'] as String?,
      createdByName: by?['name'] as String?,
      canEdit: json['canEdit'] as bool? ?? false,
    );
  }

  final String id;
  final AssessmentKind kind;
  final String courseCode;
  final String courseTitle;

  /// Local date (midnight).
  final DateTime date;

  /// Minutes after midnight; null = no time (whole day / due by end of day).
  /// For a deadline, [startMin] is the due time.
  final int? startMin;
  final int? endMin;
  final String room;
  final String topics;

  /// Who added it (null when that account was deleted).
  final String? createdById;
  final String? createdByName;

  /// The student added it or is a CR of the group.
  final bool canEdit;

  bool get hasTime => startMin != null;

  /// When it starts (or is due); the start of the day without a time.
  DateTime get startsAt => date.add(Duration(minutes: startMin ?? 0));

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'date': formatDate(date),
    'start': startMin == null ? null : Clock.format(startMin!),
    'end': endMin == null ? null : Clock.format(endMin!),
    'room': room,
    'topics': topics,
    'createdBy': createdById == null
        ? null
        : {'id': createdById, 'name': createdByName},
    'canEdit': canEdit,
  };

  AssessmentDraft toDraft() => AssessmentDraft(
    kind: kind,
    courseCode: courseCode,
    courseTitle: courseTitle,
    date: date,
    startMin: startMin,
    endMin: endMin,
    room: room,
    topics: topics,
  );
}

/// Earliest first: by date, then time (no time last), then course.
List<Assessment> sortAssessments(Iterable<Assessment> list) =>
    list.toList()..sort((a, b) {
      final d = a.date.compareTo(b.date);
      if (d != 0) return d;
      final t = (a.startMin ?? 24 * 60).compareTo(b.startMin ?? 24 * 60);
      return t != 0 ? t : a.courseCode.compareTo(b.courseCode);
    });

/// A test or deadline as a student is about to add or change it.
class AssessmentDraft {
  const AssessmentDraft({
    required this.kind,
    required this.courseCode,
    this.courseTitle = '',
    required this.date,
    this.startMin,
    this.endMin,
    this.room = '',
    this.topics = '',
  });

  final AssessmentKind kind;
  final String courseCode;
  final String courseTitle;
  final DateTime date;
  final int? startMin;
  final int? endMin;
  final String room;
  final String topics;

  Map<String, Object?> toJson() => {
    'kind': kind.wire,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'date': formatDate(date),
    if (startMin != null) 'start': Clock.format(startMin!),
    if (startMin != null && endMin != null) 'end': Clock.format(endMin!),
    'room': room,
    'topics': topics,
  };
}

/// A test or deadline with the group it belongs to.
class AssessmentInGroup {
  const AssessmentInGroup(this.assessment, this.group);

  final Assessment assessment;
  final ClassGroup group;
}

/// Tests and deadlines of all [groups] from [from] (local date) for [days]
/// days, soonest first, without the courses the student hides.
List<AssessmentInGroup> upcomingAssessments(
  List<ClassGroup> groups,
  DateTime from, {
  int days = 7,
}) {
  final first = DateTime(from.year, from.month, from.day);
  final end = DateTime(first.year, first.month, first.day + days);
  final out = <AssessmentInGroup>[
    for (final g in groups)
      for (final a in g.assessments)
        if (!a.date.isBefore(first) &&
            a.date.isBefore(end) &&
            !g.hides(a.courseCode))
          AssessmentInGroup(a, g),
  ];
  final order = sortAssessments(out.map((x) => x.assessment));
  final byId = {for (final x in out) x.assessment.id: x};
  return [for (final a in order) byId[a.id]!];
}
