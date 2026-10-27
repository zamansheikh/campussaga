import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/clock.dart';
import '../../data/reminder_scheduler.dart';
import '../../data/reminder_store.dart';

part 'reminders_state.dart';

/// Class reminders: the student's choices, the notification permission, and
/// keeping the phone's scheduled reminders in step with the routine.
///
/// Reminders are re-planned (next 14 days) whenever the routine, the
/// choices or the language change, and when the app comes to the front.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit(this._store, this._scheduler) : super(const RemindersState());

  final ReminderStore _store;
  final ReminderScheduler _scheduler;

  List<ClassGroup> _groups = const [];
  Locale _locale = const Locale('en');
  String? _lastPlan;
  Future<void> _syncing = Future.value();

  Future<void> start() async {
    await _scheduler.init();
    final settings = await _store.read();
    final granted = await _scheduler.permissionGranted();
    final exact = await _scheduler.exactAllowed();
    if (isClosed) return;
    emit(
      RemindersState(
        settings: settings,
        loaded: true,
        permissionDenied: settings.enabled && !granted,
        exactAllowed: exact,
      ),
    );
    await _sync();
  }

  /// The student's classes changed (also: signed out → empty).
  Future<void> updateGroups(List<ClassGroup> groups) {
    _groups = groups;
    return _sync();
  }

  /// Notification texts follow the app language.
  Future<void> setLocale(Locale locale) {
    if (locale == _locale) return Future.value();
    _locale = locale;
    return _sync();
  }

  /// Back in the foreground: permission may have changed in Settings, and
  /// the 14-day window moves on.
  Future<void> refresh() async {
    if (!state.loaded) return;
    final granted = await _scheduler.permissionGranted();
    final exact = await _scheduler.exactAllowed();
    if (isClosed) return;
    emit(
      state.copyWith(
        permissionDenied: state.settings.enabled && !granted,
        exactAllowed: exact,
      ),
    );
    _lastPlan = null;
    await _sync();
  }

  /// Turns reminders on, asking for permission first.
  Future<bool> enable() async {
    final granted =
        await _scheduler.permissionGranted() ||
        await _scheduler.requestPermission();
    final exact = await _scheduler.exactAllowed();
    await _save(
      state.settings.copyWith(enabled: granted, asked: true),
      permissionDenied: !granted,
      exactAllowed: exact,
    );
    return granted;
  }

  Future<void> disable() =>
      _save(state.settings.copyWith(enabled: false), permissionDenied: false);

  /// "Not now" on the Today prompt.
  Future<void> dismissPrompt() => _save(state.settings.copyWith(asked: true));

  Future<void> setMinutes(int minutes) =>
      _save(state.settings.copyWith(minutesBefore: minutes));

  Future<void> setCourseOn(String courseCode, bool on) {
    final key = ReminderSettings.courseKey(courseCode);
    final muted = {...state.settings.muted};
    on ? muted.remove(key) : muted.add(key);
    return _save(state.settings.copyWith(muted: muted));
  }

  Future<void> requestExact() async {
    await _scheduler.requestExact();
    // The answer comes from Settings; refresh() runs when the app resumes.
  }

  Future<void> _save(
    ReminderSettings settings, {
    bool? permissionDenied,
    bool? exactAllowed,
  }) async {
    emit(
      state.copyWith(
        settings: settings,
        permissionDenied: permissionDenied,
        exactAllowed: exactAllowed,
      ),
    );
    await _store.write(settings);
    await _sync();
  }

  /// Plans and schedules; skipped when nothing changed. Runs one at a time.
  Future<void> _sync() => _syncing = _syncing.then((_) async {
    if (!state.loaded || isClosed) return;
    final active = state.settings.enabled && !state.permissionDenied;
    final plan = active
        ? planReminders(
            groups: _groups,
            now: appNow(),
            settings: state.settings,
          )
        : const <PlannedReminder>[];
    final l10n = lookupAppLocalizations(_locale);
    final notes = [for (final r in plan) _notification(l10n, r)];
    final signature = [
      _locale.languageCode,
      for (final n in notes) '${n.id}|${n.at}|${n.title}|${n.body}',
    ].join('\n');
    if (signature == _lastPlan) return;
    _lastPlan = signature;
    await _scheduler.replaceAll(
      notes,
      channelName: l10n.notificationChannel,
      channelDescription: l10n.notificationChannelHint,
    );
  });

  ReminderNotification _notification(AppLocalizations l10n, PlannedReminder r) {
    final s = r.item.slot;
    return ReminderNotification(
      id: r.id,
      at: r.at,
      title: l10n.notificationTitle(s.courseCode, state.settings.minutesBefore),
      body: [
        if (s.courseTitle.isNotEmpty) s.courseTitle,
        if (r.item.room.isNotEmpty) l10n.roomShort(r.item.room),
        _time(r.item.startsAt),
      ].join(' · '),
      payload: r.item.group.id,
    );
  }

  String _time(DateTime t) {
    try {
      return DateFormat.jm(_locale.toLanguageTag()).format(t);
    } on Object {
      return Clock.format(t.hour * 60 + t.minute); // locale data not loaded
    }
  }
}
