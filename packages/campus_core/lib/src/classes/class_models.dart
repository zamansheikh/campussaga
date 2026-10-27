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

/// The id of the pseudo-group that holds the student's personal classes.
const personalGroupId = 'personal';

/// A course code in upper case without spaces ("cse 311" -> "CSE311"):
/// how hidden and muted courses are matched (same rule as the server).
String courseKey(String courseCode) =>
    courseCode.toUpperCase().replaceAll(RegExp(r'\s+'), '');

/// A student in a group, as a CR sees them (a name, never an email).
class GroupMember {
  const GroupMember({
    required this.userId,
    required this.name,
    required this.role,
    this.isMe = false,
    this.verified = true,
  });

  factory GroupMember.fromJson(Map<String, Object?> json) => GroupMember(
    userId: json['userId']! as String,
    name: json['name'] as String? ?? '',
    role: GroupRole.parse(json['role'] as String?),
    isMe: json['isMe'] as bool? ?? false,
    verified: json['verified'] as bool? ?? true,
  );

  final String userId;
  final String name;
  final GroupRole role;
  final bool isMe;

  /// Signed in with a university email (others used Gmail).
  final bool verified;
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

  /// A personal class from the API: title/details/place.
  factory ClassSlot.fromPersonalJson(Map<String, Object?> json) => ClassSlot(
    id: json['id']! as String,
    courseCode: json['title']! as String,
    courseTitle: json['details'] as String? ?? '',
    room: json['place'] as String? ?? '',
    weekday: json['weekday']! as int,
    startMin: Clock.parse(json['start']! as String),
    endMin: Clock.parse(json['end']! as String),
  );

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
    this.changes = const [],
    this.announcements = const [],
    this.hiddenCourses = const {},
  });

  /// The student's own classes, shown in the routine like a group.
  factory ClassGroup.personal(List<ClassSlot> slots) => ClassGroup(
    id: personalGroupId,
    department: '',
    batch: '',
    semester: '',
    joinCode: '',
    role: GroupRole.cr,
    memberCount: 1,
    slots: slots,
  );

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
    changes: [
      for (final c in json['changes'] as List<Object?>? ?? const [])
        ClassChange.fromJson(c! as Map<String, Object?>),
    ],
    announcements: [
      for (final a in json['announcements'] as List<Object?>? ?? const [])
        Announcement.fromJson(a! as Map<String, Object?>),
    ],
    hiddenCourses: {
      for (final c in json['hiddenCourses'] as List<Object?>? ?? const [])
        c! as String,
    },
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

  /// One-date changes from yesterday on, earliest first.
  final List<ClassChange> changes;

  /// The pinned one first, then the last 30 days' newest first.
  final List<Announcement> announcements;

  /// Course keys (see [courseKey]) the student doesn't take in this group.
  final Set<String> hiddenCourses;

  bool get isCr => role == GroupRole.cr;

  bool get isPersonal => id == personalGroupId;

  bool hides(String courseCode) =>
      hiddenCourses.contains(courseKey(courseCode));

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
    'changes': [for (final c in changes) c.toJson()],
    'announcements': [for (final a in announcements) a.toJson()],
    'hiddenCourses': hiddenCourses.toList()..sort(),
  };

  ClassGroup copyWith({
    List<ClassSlot>? slots,
    List<ClassChange>? changes,
    List<Announcement>? announcements,
    Set<String>? hiddenCourses,
    String? semester,
    GroupRole? role,
    int? memberCount,
  }) => ClassGroup(
    id: id,
    department: department,
    batch: batch,
    section: section,
    semester: semester ?? this.semester,
    joinCode: joinCode,
    role: role ?? this.role,
    memberCount: memberCount ?? this.memberCount,
    slots: slots ?? this.slots,
    changes: changes ?? this.changes,
    announcements: announcements ?? this.announcements,
    hiddenCourses: hiddenCourses ?? this.hiddenCourses,
  );
}

/// A message from the CR to the group.
class Announcement {
  const Announcement({
    required this.id,
    required this.body,
    this.pinned = false,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, Object?> json) => Announcement(
    id: json['id']! as String,
    body: json['body']! as String,
    pinned: json['pinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt']! as String).toLocal(),
  );

  final String id;
  final String body;
  final bool pinned;
  final DateTime createdAt;

  Announcement copyWith({bool? pinned}) => Announcement(
    id: id,
    body: body,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'body': body,
    'pinned': pinned,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// Pinned first, then newest first (the order the server sends).
List<Announcement> sortAnnouncements(Iterable<Announcement> list) =>
    list.toList()..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

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

  /// A personal class: the name, details and place.
  Map<String, Object?> toPersonalJson() => {
    'title': courseCode,
    'details': courseTitle,
    'place': room,
    'weekday': weekday,
    'start': Clock.format(startMin),
    'end': Clock.format(endMin),
  };
}

enum ChangeKind {
  /// The class doesn't happen on that date.
  cancelled,

  /// It happens at another time and/or room on that date.
  moved,

  /// An extra (makeup) class, not in the weekly routine.
  extra;

  static ChangeKind parse(String? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => cancelled);
}

/// A change to the routine on one date, made by the CR.
class ClassChange {
  const ClassChange({
    required this.id,
    required this.kind,
    this.slotId,
    required this.date,
    this.courseCode = '',
    this.courseTitle = '',
    this.teacher = '',
    this.classKind = ClassKind.theory,
    this.room = '',
    this.startMin,
    this.endMin,
    this.note = '',
  });

  factory ClassChange.fromJson(Map<String, Object?> json) {
    final start = json['start'] as String?;
    final end = json['end'] as String?;
    return ClassChange(
      id: json['id']! as String,
      kind: ChangeKind.parse(json['kind'] as String?),
      slotId: json['slotId'] as String?,
      date: parseDate(json['date']! as String),
      courseCode: json['courseCode'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      classKind: ClassKind.parse(json['classKind'] as String?),
      room: json['room'] as String? ?? '',
      startMin: start == null ? null : Clock.parse(start),
      endMin: end == null ? null : Clock.parse(end),
      note: json['note'] as String? ?? '',
    );
  }

  final String id;
  final ChangeKind kind;

  /// The weekly class it changes (null for an extra class).
  final String? slotId;

  /// Local date (midnight).
  final DateTime date;
  final String courseCode;
  final String courseTitle;
  final String teacher;
  final ClassKind classKind;

  /// Moved: '' = room unchanged. Extra: '' = no room given.
  final String room;
  final int? startMin;
  final int? endMin;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'slotId': slotId,
    'date': formatDate(date),
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'teacher': teacher,
    'classKind': classKind.name,
    'room': room,
    'start': startMin == null ? null : Clock.format(startMin!),
    'end': endMin == null ? null : Clock.format(endMin!),
    'note': note,
  };
}

/// "2026-10-28" <-> local midnight.
DateTime parseDate(String yyyyMmDd) {
  final p = yyyyMmDd.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// A change the CR is about to make.
class ChangeDraft {
  const ChangeDraft.cancel({
    required this.slotId,
    required this.date,
    this.note = '',
  }) : kind = ChangeKind.cancelled,
       startMin = null,
       endMin = null,
       room = '',
       courseCode = '',
       courseTitle = '',
       teacher = '',
       classKind = ClassKind.theory;

  const ChangeDraft.move({
    required this.slotId,
    required this.date,
    required int this.startMin,
    required int this.endMin,
    this.room = '',
    this.note = '',
  }) : kind = ChangeKind.moved,
       courseCode = '',
       courseTitle = '',
       teacher = '',
       classKind = ClassKind.theory;

  const ChangeDraft.extra({
    required this.date,
    required this.courseCode,
    required int this.startMin,
    required int this.endMin,
    this.courseTitle = '',
    this.teacher = '',
    this.room = '',
    this.classKind = ClassKind.theory,
    this.note = '',
  }) : kind = ChangeKind.extra,
       slotId = null;

  final ChangeKind kind;
  final String? slotId;
  final DateTime date;
  final int? startMin;
  final int? endMin;
  final String room;
  final String courseCode;
  final String courseTitle;
  final String teacher;
  final ClassKind classKind;
  final String note;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'slotId': ?slotId,
    'date': formatDate(date),
    if (startMin != null) 'start': Clock.format(startMin!),
    if (endMin != null) 'end': Clock.format(endMin!),
    'room': room,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'teacher': teacher,
    'classKind': classKind.name,
    'note': note,
  };
}

/// One class on a given date, with the group it comes from and the CR's
/// change for that date, if any. Times and room are the ones that apply
/// on that date.
class ClassOnDay {
  const ClassOnDay({
    required this.slot,
    required this.group,
    required this.date,
    this.change,
  });

  /// The weekly class (for an extra class: built from the change).
  final ClassSlot slot;
  final ClassGroup group;
  final DateTime date;
  final ClassChange? change;

  bool get cancelled => change?.kind == ChangeKind.cancelled;
  bool get moved => change?.kind == ChangeKind.moved;
  bool get extra => change?.kind == ChangeKind.extra;

  int get startMin => moved ? change!.startMin! : slot.startMin;
  int get endMin => moved ? change!.endMin! : slot.endMin;
  String get room =>
      moved && change!.room.isNotEmpty ? change!.room : slot.room;

  bool get timeChanged =>
      moved && (startMin != slot.startMin || endMin != slot.endMin);
  bool get roomChanged => moved && room != slot.room;

  DateTime get startsAt => date.add(Duration(minutes: startMin));
  DateTime get endsAt => date.add(Duration(minutes: endMin));
}

/// The classes of all [groups] on [day] (local date), earliest first, with
/// that date's changes applied: cancelled classes are kept (marked), moved
/// ones use their new time and room, extra classes are added.
List<ClassOnDay> classesOn(List<ClassGroup> groups, DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  final out = <ClassOnDay>[];
  for (final g in groups) {
    final today = {
      for (final c in g.changes)
        if (c.date == date) c.slotId ?? c.id: c,
    };
    for (final s in g.slots) {
      if (s.weekday == date.weekday && !g.hides(s.courseCode)) {
        out.add(ClassOnDay(slot: s, group: g, date: date, change: today[s.id]));
      }
    }
    for (final c in today.values) {
      if (c.kind != ChangeKind.extra || g.hides(c.courseCode)) continue;
      out.add(
        ClassOnDay(
          slot: ClassSlot(
            id: c.id,
            courseCode: c.courseCode,
            courseTitle: c.courseTitle,
            teacher: c.teacher,
            room: c.room,
            weekday: date.weekday,
            startMin: c.startMin!,
            endMin: c.endMin!,
            kind: c.classKind,
          ),
          group: g,
          date: date,
          change: c,
        ),
      );
    }
  }
  return out..sort((a, b) {
    final t = a.startMin.compareTo(b.startMin);
    return t != 0 ? t : a.slot.courseCode.compareTo(b.slot.courseCode);
  });
}
