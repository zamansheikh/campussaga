part of 'reminders_cubit.dart';

class RemindersState extends Equatable {
  const RemindersState({
    this.settings = const ReminderSettings(),
    this.loaded = false,
    this.permissionDenied = false,
    this.exactAllowed = true,
  });

  final ReminderSettings settings;
  final bool loaded;

  /// Reminders are on, but the phone blocks this app's notifications.
  final bool permissionDenied;

  /// Android: alarms may run late unless "Alarms & reminders" is allowed.
  final bool exactAllowed;

  bool get active => settings.enabled && !permissionDenied;

  RemindersState copyWith({
    ReminderSettings? settings,
    bool? permissionDenied,
    bool? exactAllowed,
  }) => RemindersState(
    settings: settings ?? this.settings,
    loaded: loaded,
    permissionDenied: permissionDenied ?? this.permissionDenied,
    exactAllowed: exactAllowed ?? this.exactAllowed,
  );

  @override
  List<Object?> get props => [settings, loaded, permissionDenied, exactAllowed];
}
