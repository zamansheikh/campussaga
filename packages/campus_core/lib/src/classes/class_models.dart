/// A student's role in a class group.
enum GroupRole {
  /// Class representative: keeps the routine up to date.
  cr,
  member;

  static GroupRole parse(String? v) => v == 'cr' ? cr : member;
}

enum ClassKind {
  theory,
  lab;

  static ClassKind parse(String? v) => v == 'lab' ? lab : theory;
}

/// Minutes after midnight <-> "HH:MM".
abstract final class Clock {
  static int parse(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}

/// One weekly class. [weekday] is ISO / `DateTime.weekday` (1 = Monday ...
/// 7 = Sunday); times are minutes after midnight, local time.
class ClassSlot {
  const ClassSlot({
    required this.id,
    required this.courseCode,
    this.courseTitle = '',
    this.teacher = '',
    this.room = '',
    required this.weekday,
    required this.startMin,
    required this.endMin,
    this.kind = ClassKind.theory,
  });

  factory ClassSlot.fromJson(Map<String, Object?> json) => ClassSlot(
    id: json['id']! as String,
    courseCode: json['courseCode']! as String,
    courseTitle: json['courseTitle'] as String? ?? '',
    teacher: json['teacher'] as String? ?? '',
    room: json['room'] as String? ?? '',
    weekday: json['weekday']! as int,
    startMin: Clock.parse(json['start']! as String),
    endMin: Clock.parse(json['end']! as String),
    kind: ClassKind.parse(json['kind'] as String?),
  );

  final String id;
  final String courseCode;
  final String courseTitle;
  final String teacher;
  final String room;
  final int weekday;
  final int startMin;
  final int endMin;
  final ClassKind kind;

  Map<String, Object?> toJson() => {
    'id': id,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'teacher': teacher,
    'room': room,
    'weekday': weekday,
    'start': Clock.format(startMin),
    'end': Clock.format(endMin),
    'kind': kind.name,
  };

  SlotDraft toDraft() => SlotDraft(
    courseCode: courseCode,
    courseTitle: courseTitle,
    teacher: teacher,
    room: room,
    weekday: weekday,
    startMin: startMin,
    endMin: endMin,
    kind: kind,
  );
}

/// A section's routine group, as one of its members sees it.
class ClassGroup {
  const ClassGroup({
    required this.id,
    required this.department,
    required this.batch,
    this.section = '',
    required this.semester,
    required this.joinCode,
    required this.role,
    required this.memberCount,
    this.slots = const [],
  });

  factory ClassGroup.fromJson(Map<String, Object?> json) => ClassGroup(
    id: json['id']! as String,
    department: json['department']! as String,
    batch: json['batch']! as String,
    section: json['section'] as String? ?? '',
    semester: json['semester']! as String,
    joinCode: json['joinCode']! as String,
    role: GroupRole.parse(json['role'] as String?),
    memberCount: json['memberCount']! as int,
    slots: [
      for (final s in json['slots'] as List<Object?>? ?? const [])
        ClassSlot.fromJson(s! as Map<String, Object?>),
    ],
  );

  final String id;
  final String department;
  final String batch;
  final String section;
  final String semester;
  final String joinCode;
  final GroupRole role;
  final int memberCount;
  final List<ClassSlot> slots;

  bool get isCr => role == GroupRole.cr;

  /// "CSE 61 · A"
  String get title =>
      [department, batch].join(' ') + (section.isEmpty ? '' : ' · $section');

  Map<String, Object?> toJson() => {
    'id': id,
    'department': department,
    'batch': batch,
    'section': section,
    'semester': semester,
    'joinCode': joinCode,
    'role': role.name,
    'memberCount': memberCount,
    'slots': [for (final s in slots) s.toJson()],
  };

  ClassGroup copyWith({List<ClassSlot>? slots, int? memberCount}) => ClassGroup(
    id: id,
    department: department,
    batch: batch,
    section: section,
    semester: semester,
    joinCode: joinCode,
    role: role,
    memberCount: memberCount ?? this.memberCount,
    slots: slots ?? this.slots,
  );
}

/// What a join code leads to, shown before joining.
class GroupPreview {
  const GroupPreview({
    required this.department,
    required this.batch,
    this.section = '',
    required this.semester,
    required this.memberCount,
    required this.classCount,
    required this.isMember,
  });

  factory GroupPreview.fromJson(Map<String, Object?> json) => GroupPreview(
    department: json['department']! as String,
    batch: json['batch']! as String,
    section: json['section'] as String? ?? '',
    semester: json['semester']! as String,
    memberCount: json['memberCount']! as int,
    classCount: json['classCount']! as int,
    isMember: json['isMember'] as bool? ?? false,
  );

  final String department;
  final String batch;
  final String section;
  final String semester;
  final int memberCount;
  final int classCount;
  final bool isMember;

  String get title =>
      [department, batch].join(' ') + (section.isEmpty ? '' : ' · $section');
}

/// Group details entered by the CR.
class GroupDraft {
  const GroupDraft({
    required this.department,
    required this.batch,
    this.section = '',
    required this.semester,
  });

  final String department;
  final String batch;
  final String section;
  final String semester;

  Map<String, Object?> toJson() => {
    'department': department,
    'batch': batch,
    'section': section,
    'semester': semester,
  };
}

/// One class as entered by the CR.
class SlotDraft {
  const SlotDraft({
    required this.courseCode,
    this.courseTitle = '',
    this.teacher = '',
    this.room = '',
    required this.weekday,
    required this.startMin,
    required this.endMin,
    this.kind = ClassKind.theory,
  });

  final String courseCode;
  final String courseTitle;
  final String teacher;
  final String room;
  final int weekday;
  final int startMin;
  final int endMin;
  final ClassKind kind;

  Map<String, Object?> toJson() => {
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'teacher': teacher,
    'room': room,
    'weekday': weekday,
    'start': Clock.format(startMin),
    'end': Clock.format(endMin),
    'kind': kind.name,
  };
}

/// One class on a given date, with the group it comes from.
class ClassOnDay {
  const ClassOnDay({
    required this.slot,
    required this.group,
    required this.date,
  });

  final ClassSlot slot;
  final ClassGroup group;
  final DateTime date;

  DateTime get startsAt => date.add(Duration(minutes: slot.startMin));
  DateTime get endsAt => date.add(Duration(minutes: slot.endMin));
}

/// The classes of all [groups] on [day] (local date), earliest first.
List<ClassOnDay> classesOn(List<ClassGroup> groups, DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  final out =
      [
        for (final g in groups)
          for (final s in g.slots)
            if (s.weekday == date.weekday)
              ClassOnDay(slot: s, group: g, date: date),
      ]..sort((a, b) {
        final t = a.slot.startMin.compareTo(b.slot.startMin);
        return t != 0 ? t : a.slot.courseCode.compareTo(b.slot.courseCode);
      });
  return out;
}
