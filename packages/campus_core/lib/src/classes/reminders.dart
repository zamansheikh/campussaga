import 'assessment_models.dart';
import 'class_models.dart';

// Outside the class, where [courseKey] means the top-level function.
String _key(String code) => courseKey(code);

/// The student's reminder choices (saved on the phone).
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.minutesBefore = 10,
    this.muted = const {},
    this.asked = false,
  });

  factory ReminderSettings.fromJson(Map<String, Object?> json) =>
      ReminderSettings(
        enabled: json['enabled'] as bool? ?? false,
        minutesBefore: json['minutesBefore'] as int? ?? 10,
        muted: {
          for (final c in json['muted'] as List<Object?>? ?? const [])
            c! as String,
        },
        asked: json['asked'] as bool? ?? false,
      );

  /// Choices offered in the app.
  static const minuteChoices = [5, 10, 15, 30];

  final bool enabled;
  final int minutesBefore;

  /// Course codes (upper case, no spaces) with reminders turned off.
  final Set<String> muted;

  /// The student has been asked once (the Today prompt is not shown again).
  final bool asked;

  static String courseKey(String code) => _key(code);

  bool isMuted(String courseCode) => muted.contains(_key(courseCode));

  ReminderSettings copyWith({
    bool? enabled,
    int? minutesBefore,
    Set<String>? muted,
    bool? asked,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    minutesBefore: minutesBefore ?? this.minutesBefore,
    muted: muted ?? this.muted,
    asked: asked ?? this.asked,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'minutesBefore': minutesBefore,
    'muted': muted.toList()..sort(),
    'asked': asked,
  };

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.minutesBefore == minutesBefore &&
      other.asked == asked &&
      other.muted.length == muted.length &&
      other.muted.containsAll(muted);

  @override
  int get hashCode => Object.hash(
    enabled,
    minutesBefore,
    asked,
    Object.hashAllUnordered(muted),
  );
}

/// Which reminder of a test or deadline.
enum AssessmentReminder {
  /// 8 PM the evening before.
  eveningBefore,

  /// 1 hour before it starts (9 AM that day when it has no time).
  soon,
}

/// One reminder to show at [at]: for a class ([item]) or for a test or
/// deadline ([assessment] in [group], which reminder: [when]).
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required ClassOnDay this.item,
  }) : assessment = null,
       group = null,
       when = null;

  const PlannedReminder.assessment({
    required this.id,
    required this.at,
    required Assessment this.assessment,
    required ClassGroup this.group,
    required AssessmentReminder this.when,
  }) : item = null;

  final int id;
  final DateTime at;
  final ClassOnDay? item;
  final Assessment? assessment;
  final ClassGroup? group;
  final AssessmentReminder? when;

  /// The group to open when it's tapped.
  String get groupId => item?.group.id ?? group!.id;
}

/// Reminder times of tests and deadlines.
const assessmentEveningHour = 20;
const assessmentMorningHour = 9;
const assessmentLeadTime = Duration(hours: 1);

/// The reminders for the next [days] days after [now], earliest first, at
/// most [max] (iOS keeps only 64 pending notifications per app): one before
/// each class, and two for each test or deadline (the evening before and
/// shortly before). Phones re-plan whenever the app opens or the routine
/// changes, so a rolling window is enough.
List<PlannedReminder> planReminders({
  required List<ClassGroup> groups,
  required DateTime now,
  required ReminderSettings settings,
  int days = 14,
  int max = 60,
}) {
  if (!settings.enabled) return const [];
  final before = Duration(minutes: settings.minutesBefore);
  final out = <_Planned>[];
  final seen = <String>{};
  for (var i = 0; i < days; i++) {
    final day = DateTime(now.year, now.month, now.day + i);
    for (final c in classesOn(groups, day)) {
      if (c.off || settings.isMuted(c.slot.courseCode)) continue;
      final at = c.startsAt.subtract(before);
      if (!at.isAfter(now)) continue;
      // The same course at the same time in two groups: one reminder.
      final key = '${_key(c.slot.courseCode)}@${c.startsAt}';
      if (seen.add(key)) out.add(_Planned(at, item: c));
    }
  }

  final today = DateTime(now.year, now.month, now.day);
  final end = DateTime(today.year, today.month, today.day + days);
  for (final g in groups) {
    for (final a in g.assessments) {
      if (a.date.isBefore(today) || !a.date.isBefore(end)) continue;
      if (g.hides(a.courseCode) || settings.isMuted(a.courseCode)) continue;
      // The same test shared by two groups: one set of reminders.
      if (!seen.add('${_key(a.courseCode)}#${a.kind.wire}@${a.date}')) {
        continue;
      }
      final evening = DateTime(
        a.date.year,
        a.date.month,
        a.date.day - 1,
        assessmentEveningHour,
      );
      final soon = a.hasTime
          ? a.startsAt.subtract(assessmentLeadTime)
          : a.date.add(const Duration(hours: assessmentMorningHour));
      for (final (at, which) in [
        (evening, AssessmentReminder.eveningBefore),
        (soon, AssessmentReminder.soon),
      ]) {
        if (at.isAfter(now)) {
          out.add(_Planned(at, assessment: a, group: g, when: which));
        }
      }
    }
  }

  out.sort((a, b) => a.at.compareTo(b.at));
  return [
    for (var i = 0; i < out.length && i < max; i++) out[i].toReminder(i + 1),
  ];
}

class _Planned {
  _Planned(this.at, {this.item, this.assessment, this.group, this.when});

  final DateTime at;
  final ClassOnDay? item;
  final Assessment? assessment;
  final ClassGroup? group;
  final AssessmentReminder? when;

  PlannedReminder toReminder(int id) => item != null
      ? PlannedReminder(id: id, at: at, item: item!)
      : PlannedReminder.assessment(
          id: id,
          at: at,
          assessment: assessment!,
          group: group!,
          when: when!,
        );
}
