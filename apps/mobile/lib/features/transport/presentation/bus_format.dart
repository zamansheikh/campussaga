import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/widgets.dart';

import '../../auth/presentation/auth_error_text.dart';
import '../../classes/presentation/class_format.dart';

/// "Sat–Thu", "Sat, Mon, Wed" or "Every day": runs of days in the
/// Saturday-first week are shortened.
String weekdaysText(BuildContext context, Set<int> days) {
  if (days.length == 7) return AppLocalizations.of(context).busEveryDay;
  final order = [for (final d in weekOrder) d];
  final parts = <String>[];
  var i = 0;
  while (i < order.length) {
    if (!days.contains(order[i])) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < order.length && days.contains(order[j + 1])) {
      j++;
    }
    parts.add(
      j - i >= 2
          ? '${weekdayShort(context, order[i])}–${weekdayShort(context, order[j])}'
          : [for (var k = i; k <= j; k++) weekdayShort(context, order[k])]
                .join(', '),
    );
    i = j + 1;
  }
  return parts.join(', ');
}

/// "in 12 min", "in 1 h 5 min", or "Today/Tomorrow/Wed, Oct 28" + time.
String whenText(BuildContext context, DateTime at, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final mins = at.difference(now).inMinutes;
  if (mins < 60) return l10n.startsInMinutes(mins < 1 ? 1 : mins);
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  if (sameDay && mins < 180) return l10n.startsInHours(mins ~/ 60, mins % 60);
  return '${dayText(context, at, now)}, ${clockText(context, at.hour * 60 + at.minute)}';
}

/// The time of day of [at] ("8:15 AM").
String timeOf(BuildContext context, DateTime at) =>
    clockText(context, at.hour * 60 + at.minute);

String busErrorText(AppLocalizations l10n, Failure f) => switch (f.code) {
  'NOT_TRANSPORT_REP' => l10n.busNotRep,
  'ROUTE_NOT_FOUND' => l10n.busRouteNotFound,
  _ => authErrorText(l10n, f),
};

/// Route colours reps can pick from.
const busColors = [
  '#0F766E',
  '#2563EB',
  '#7C3AED',
  '#DB2777',
  '#DC2626',
  '#EA580C',
  '#CA8A04',
  '#16A34A',
];
