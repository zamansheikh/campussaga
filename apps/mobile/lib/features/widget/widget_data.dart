import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:intl/intl.dart';

import 'widget_texts.dart';

/// How far ahead the widget knows classes and tests (it picks the next one
/// itself, by the phone's clock, so it stays right while the app is closed).
const widgetDays = 14;
const _maxClasses = 80;
const _maxTests = 40;

/// The JSON NextClassWidget.kt reads. [routine] is every group plus the
/// personal classes (MyClassesState.routine). Needs intl date symbols for
/// [lang] (initializeDateFormatting).
String buildWidgetJson({
  required List<ClassGroup> routine,
  required DateTime now,
  required String lang,
  required bool signedIn,
}) => jsonEncode(
  buildWidgetData(routine: routine, now: now, lang: lang, signedIn: signedIn),
);

Map<String, Object?> buildWidgetData({
  required List<ClassGroup> routine,
  required DateTime now,
  required String lang,
  required bool signedIn,
}) {
  final t = WidgetTexts.of(lang);
  if (!signedIn) {
    return {
      'v': 1,
      'lang': t.lang,
      'signedIn': false,
      'labels': {'signedOut': t.labels['signedOut']},
    };
  }
  final locale = t.lang;
  final clock = DateFormat.jm(locale);
  final dateFmt = DateFormat('EEE d MMM', locale);
  String time(DateTime day, int min) =>
      clock.format(day.add(Duration(minutes: min)));
  String room(String r) => r.isEmpty ? '' : '${t.room} $r';
  String join(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join(' · ');

  final today = DateTime(now.year, now.month, now.day);

  // Classes that still happen in the window, earliest first.
  final classes = <Map<String, Object?>>[];
  for (var i = 0; i < widgetDays && classes.length < _maxClasses; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    for (final c in classesOn(routine, day)) {
      if (c.off || !c.endsAt.isAfter(now)) continue;
      classes.add({
        'start': c.startsAt.millisecondsSinceEpoch,
        'end': c.endsAt.millisecondsSinceEpoch,
        'course': c.slot.courseCode,
        'badge': c.extra ? t.extra : (c.moved ? t.moved : ''),
        'line': join([
          '${time(day, c.startMin)} – ${time(day, c.endMin)}',
          room(c.room),
        ]),
        'date': dateFmt.format(day),
      });
      if (classes.length >= _maxClasses) break;
    }
  }

  // Tests and deadlines not yet over, earliest first.
  final end = DateTime(today.year, today.month, today.day + widgetDays);
  final tests = <(DateTime, String, Map<String, Object?>)>[];
  for (final g in routine) {
    for (final a in g.assessments) {
      if (g.hides(a.courseCode)) continue;
      if (a.date.isBefore(today) || !a.date.isBefore(end)) continue;
      final at = a.startsAt;
      final until = a.endMin != null
          ? a.date.add(Duration(minutes: a.endMin!))
          : a.startMin != null
          ? at.add(const Duration(hours: 1))
          : DateTime(a.date.year, a.date.month, a.date.day + 1);
      if (!until.isAfter(now)) continue;
      final when = a.startMin == null
          ? ''
          : a.endMin == null
          ? time(a.date, a.startMin!)
          : '${time(a.date, a.startMin!)} – ${time(a.date, a.endMin!)}';
      tests.add((
        at,
        a.courseCode,
        {
          'at': at.millisecondsSinceEpoch,
          'until': until.millisecondsSinceEpoch,
          'title': '${t.kind(a.kind)} · ${a.courseCode}',
          'time': join([
            if (when.isNotEmpty) a.kind.isDeadline ? '${t.due} $when' : when,
            room(a.room),
          ]),
          'date': dateFmt.format(a.date),
        },
      ));
    }
  }
  tests.sort((x, y) {
    final d = x.$1.compareTo(y.$1);
    return d != 0 ? d : x.$2.compareTo(y.$2);
  });

  return {
    'v': 1,
    'lang': t.lang,
    'signedIn': true,
    'labels': t.labels,
    'classes': classes,
    'tests': [for (final x in tests.take(_maxTests)) x.$3],
  };
}
