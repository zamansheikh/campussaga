import 'class_models.dart';

/// "Find your class": a class group of the student's university, as search
/// shows it (no member list).
class FoundGroup {
  const FoundGroup({
    required this.id,
    required this.department,
    required this.batch,
    this.section = '',
    required this.semester,
    required this.memberCount,
    this.crName,
    this.courses = const [],
    this.isMember = false,
  });

  factory FoundGroup.fromJson(Map<String, Object?> json) => FoundGroup(
    id: json['id']! as String,
    department: json['department']! as String,
    batch: json['batch']! as String,
    section: json['section'] as String? ?? '',
    semester: json['semester'] as String? ?? '',
    memberCount: json['memberCount'] as int? ?? 0,
    crName: json['crName'] as String?,
    courses: [
      for (final c in json['courses'] as List<Object?>? ?? const [])
        FoundCourse.fromJson(c! as Map<String, Object?>),
    ],
    isMember: json['isMember'] as bool? ?? false,
  );

  final String id;
  final String department;
  final String batch;
  final String section;
  final String semester;
  final int memberCount;

  /// The CR's name (null when they haven't set one).
  final String? crName;
  final List<FoundCourse> courses;

  /// The student is already in this group.
  final bool isMember;

  /// "CSE 61 · A"
  String get title =>
      [department, batch].join(' ') + (section.isEmpty ? '' : ' · $section');
}

/// One course of a found group's routine.
class FoundCourse {
  const FoundCourse({
    required this.key,
    required this.code,
    this.title = '',
    this.teacher = '',
  });

  factory FoundCourse.fromJson(Map<String, Object?> json) => FoundCourse(
    key: json['key'] as String? ?? courseKey(json['code']! as String),
    code: json['code']! as String,
    title: json['title'] as String? ?? '',
    teacher: json['teacher'] as String? ?? '',
  );

  /// [courseKey] of [code]: "CSE311".
  final String key;
  final String code;
  final String title;
  final String teacher;
}

/// One page of search results.
class GroupSearchPage {
  const GroupSearchPage({required this.items, this.more = false});

  factory GroupSearchPage.fromJson(Map<String, Object?> json) =>
      GroupSearchPage(
        items: [
          for (final g in json['items'] as List<Object?>? ?? const [])
            FoundGroup.fromJson(g! as Map<String, Object?>),
        ],
        more: json['more'] as bool? ?? false,
      );

  final List<FoundGroup> items;

  /// Another page exists.
  final bool more;
}

/// A group's weekly routine before joining.
class RoutinePreview {
  const RoutinePreview({
    required this.group,
    this.slots = const [],
    this.hiddenCourses = const {},
  });

  factory RoutinePreview.fromJson(Map<String, Object?> json) => RoutinePreview(
    group: FoundGroup.fromJson(json),
    slots: [
      for (final s in json['slots'] as List<Object?>? ?? const [])
        ClassSlot.fromJson(s! as Map<String, Object?>),
    ],
    hiddenCourses: {
      for (final c in json['hiddenCourses'] as List<Object?>? ?? const [])
        c! as String,
    },
  );

  final FoundGroup group;
  final List<ClassSlot> slots;

  /// Course keys a member doesn't take (empty for non-members).
  final Set<String> hiddenCourses;
}
