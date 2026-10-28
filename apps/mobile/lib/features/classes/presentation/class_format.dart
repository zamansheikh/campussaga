import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_error_text.dart';

/// Saturday-first week, as most Bangladeshi university routines are.
const weekOrder = [6, 7, 1, 2, 3, 4, 5];

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "Tuesday" for ISO weekday 2, in the app language.
String weekdayName(BuildContext context, int weekday) =>
    DateFormat.EEEE(_locale(context))
        .format(DateTime(2024, 1, weekday)); // 1 Jan 2024 was a Monday

String weekdayShort(BuildContext context, int weekday) =>
    DateFormat.E(_locale(context)).format(DateTime(2024, 1, weekday));

/// "8:30 AM" (or the Bangla form) for minutes after midnight.
String clockText(BuildContext context, int minutes) =>
    DateFormat.jm(_locale(context))
        .format(DateTime(2024, 1, 1).add(Duration(minutes: minutes)));

/// "8:30 – 10:00 AM" style range.
String rangeText(BuildContext context, ClassSlot s) =>
    '${clockText(context, s.startMin)} – ${clockText(context, s.endMin)}';

/// The student-facing message for a class group failure.
String classErrorText(AppLocalizations l10n, Failure f) => switch (f.code) {
  'GROUP_NOT_FOUND' => l10n.errorGroupNotFound,
  'UNIVERSITY_REQUIRED' => l10n.errorUniversityRequired,
  'NOT_GROUP_CR' => l10n.errorNotCr,
  'GROUP_LIMIT_REACHED' => l10n.errorGroupLimit,
  'GROUP_FULL' => l10n.errorGroupFull,
  'CR_CANNOT_LEAVE' => l10n.errorCrCannotLeave,
  'SLOT_LIMIT_REACHED' => l10n.errorSlotLimit,
  'ANNOUNCEMENT_NOT_FOUND' => l10n.errorAnnouncementGone,
  'CR_LIMIT_REACHED' => l10n.errorCrLimit,
  'LAST_CR' => l10n.errorLastCr,
  'REMOVE_CR' => l10n.errorRemoveCr,
  'PERSONAL_LIMIT_REACHED' => l10n.errorPersonalLimit,
  'ASSESSMENT_LIMIT_REACHED' => l10n.errorAssessmentLimit,
  'ASSESSMENT_NOT_FOUND' => l10n.errorAssessmentGone,
  'NOT_ASSESSMENT_OWNER' => l10n.errorNotAssessmentOwner,
  _ when _field(f, 'newDate') => l10n.errorMoveDate,
  _ when _field(f, 'date') => l10n.errorAssessmentDate,
  _ when f is RateLimitedFailure => l10n.errorTooManyRequests,
  _ => authErrorText(l10n, f),
};

/// "just now", "5 min ago", "3 h ago", "yesterday", or the date.
String agoText(BuildContext context, DateTime t, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final d = now.difference(t);
  if (d.inMinutes < 1) return l10n.timeJustNow;
  if (d.inMinutes < 60) return l10n.timeMinutesAgo(d.inMinutes);
  final today = DateTime(now.year, now.month, now.day);
  if (!t.isBefore(today)) return l10n.timeHoursAgo(d.inHours);
  if (!t.isBefore(today.subtract(const Duration(days: 1)))) {
    return l10n.timeYesterday;
  }
  return DateFormat.MMMd(_locale(context)).format(t);
}

/// How a group is named in lists: its title, or "Personal".
String groupLabel(BuildContext context, ClassGroup g) =>
    g.isPersonal ? AppLocalizations.of(context).personalClasses : g.title;

bool _field(Failure f, String name) =>
    f is ValidationFailure && f.fieldErrors.containsKey(name);

/// "Wed, Oct 28" (or the Bangla form).
String shortDate(BuildContext context, DateTime d) =>
    DateFormat.MMMEd(_locale(context)).format(d);

/// "Today", "Tomorrow", or [shortDate].
String dayText(BuildContext context, DateTime d, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return l10n.dayToday;
  if (day == DateTime(today.year, today.month, today.day + 1)) {
    return l10n.dayTomorrow;
  }
  return shortDate(context, d);
}

/// "Class test", "Assignment", ...
String assessmentKindText(AppLocalizations l10n, AssessmentKind k) =>
    switch (k) {
      AssessmentKind.classTest => l10n.kindClassTest,
      AssessmentKind.quiz => l10n.kindQuiz,
      AssessmentKind.assignment => l10n.kindAssignment,
      AssessmentKind.labReport => l10n.kindLabReport,
      AssessmentKind.presentation => l10n.kindPresentation,
      AssessmentKind.midterm => l10n.kindMidterm,
      AssessmentKind.finalExam => l10n.kindFinal,
      AssessmentKind.other => l10n.kindOther,
    };

/// "10:00 AM", "10:00 – 10:30 AM", "Due 11:59 PM", or "" without a time.
String assessmentTimeText(BuildContext context, Assessment a) {
  final start = a.startMin;
  if (start == null) return '';
  if (a.kind.isDeadline) {
    return AppLocalizations.of(context).dueAt(clockText(context, start));
  }
  final end = a.endMin;
  return end == null
      ? clockText(context, start)
      : '${clockText(context, start)} – ${clockText(context, end)}';
}
