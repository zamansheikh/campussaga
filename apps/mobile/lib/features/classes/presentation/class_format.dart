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
  'NOT_GROUP_CR' => l10n.errorNotCr,
  'GROUP_LIMIT_REACHED' => l10n.errorGroupLimit,
  'GROUP_FULL' => l10n.errorGroupFull,
  'CR_CANNOT_LEAVE' => l10n.errorCrCannotLeave,
  'SLOT_LIMIT_REACHED' => l10n.errorSlotLimit,
  _ when f is RateLimitedFailure => l10n.errorTooManyRequests,
  _ => authErrorText(l10n, f),
};
