import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One notification to show at [at].
class ReminderNotification {
  const ReminderNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String? payload;
}

/// Shows class reminders through the phone's notification system. The
/// phone keeps them, so they fire with the app closed, offline, and (on
/// Android) after a restart.
abstract interface class ReminderScheduler {
  Future<void> init();

  Future<bool> permissionGranted();

  /// Asks the student (shows the system prompt once).
  Future<bool> requestPermission();

  /// Android 12+ may delay alarms unless "Alarms & reminders" is allowed.
  Future<bool> exactAllowed();

  Future<void> requestExact();

  /// Replaces every pending reminder with [reminders].
  Future<void> replaceAll(
    List<ReminderNotification> reminders, {
    required String channelName,
    required String channelDescription,
  });
}

class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  bool? _exact;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init() => _ready ??= _init();

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permission is asked from the app at the right moment, not at start.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> permissionGranted() async {
    await init();
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return (await _ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (_android != null) {
      return await _android!.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<bool> exactAllowed() async {
    await init();
    return _exact = await _android?.canScheduleExactNotifications() ?? true;
  }

  @override
  Future<void> requestExact() async {
    await init();
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> replaceAll(
    List<ReminderNotification> reminders, {
    required String channelName,
    required String channelDescription,
  }) async {
    await init();
    final exact = _exact ?? await exactAllowed();
    await _plugin.cancelAllPendingNotifications();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'class_reminders',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        payload: r.payload,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

/// Keeps reminders in memory (tests).
class MemoryReminderScheduler implements ReminderScheduler {
  bool granted = false;

  /// What the system prompt answers.
  bool grantOnRequest = true;
  bool exact = true;
  int requests = 0;
  List<ReminderNotification> pending = const [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return granted = grantOnRequest;
  }

  @override
  Future<bool> exactAllowed() async => exact;

  @override
  Future<void> requestExact() async => exact = true;

  @override
  Future<void> replaceAll(
    List<ReminderNotification> reminders, {
    required String channelName,
    required String channelDescription,
  }) async => pending = List.of(reminders);
}
