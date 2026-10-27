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

/// One reminder to show at [at], for [item].
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.item,
  });

  final int id;
  final DateTime at;
  final ClassOnDay item;
}

/// The reminders for the next [days] days after [now], earliest first, at
/// most [max] (iOS keeps only 64 pending notifications per app). Phones
/// re-plan whenever the app opens or the routine changes, so a rolling
/// window is enough and leaves room to skip single cancelled classes later.
List<PlannedReminder> planReminders({
  required List<ClassGroup> groups,
  required DateTime now,
  required ReminderSettings settings,
  int days = 14,
  int max = 60,
}) {
  if (!settings.enabled) return const [];
  final before = Duration(minutes: settings.minutesBefore);
  final out = <(DateTime, ClassOnDay)>[];
  final seen = <String>{};
  for (var i = 0; i < days; i++) {
    final day = DateTime(now.year, now.month, now.day + i);
    for (final c in classesOn(groups, day)) {
      if (c.cancelled || settings.isMuted(c.slot.courseCode)) continue;
      final at = c.startsAt.subtract(before);
      if (!at.isAfter(now)) continue;
      // The same course at the same time in two groups: one reminder.
      final key = '${_key(c.slot.courseCode)}@${c.startsAt}';
      if (seen.add(key)) out.add((at, c));
    }
  }
  out.sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (var i = 0; i < out.length && i < max; i++)
      PlannedReminder(id: i + 1, at: out[i].$1, item: out[i].$2),
  ];
}
