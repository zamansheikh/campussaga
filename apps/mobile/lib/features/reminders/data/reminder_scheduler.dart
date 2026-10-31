import 'package:flutter/services.dart';
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

  /// Creates (or renames) the Android channel pushes use, so the phone can
  /// show them in the student's language even when the app is closed.
  Future<void> prepareUpdatesChannel({
    required String name,
    required String description,
  });

  /// Shows a push that arrived while the app is open.
  Future<void> showUpdate({
    required String title,
    required String body,
    String? payload,
  });
}

/// The Android channel for pushes (changes, announcements); the server
/// sends this id.
const updatesChannelId = 'class_updates';

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
    try {
      await _initializePlugin('ic_notification');
    } on PlatformException catch (e) {
      // The small icon wasn't found by name (seen once on an Android 11
      // OnePlus): use the app icon rather than leave reminders off.
      if (e.code != 'invalid_icon') rethrow;
      await _initializePlugin('@mipmap/ic_launcher');
    }
  }

  Future<void> _initializePlugin(String icon) => _plugin.initialize(
    settings: InitializationSettings(
      android: AndroidInitializationSettings(icon),
      // Permission is asked from the app at the right moment, not at start.
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

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

  String _updatesName = 'Class updates';
  String _updatesDescription = '';
  int _updateId = 100000; // after reminder ids

  @override
  Future<void> prepareUpdatesChannel({
    required String name,
    required String description,
  }) async {
    await init();
    _updatesName = name;
    _updatesDescription = description;
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        updatesChannelId,
        name,
        description: description,
        importance: Importance.high,
      ),
    );
  }

  @override
  Future<void> showUpdate({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await _plugin.show(
      id: _updateId++,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          updatesChannelId,
          _updatesName,
          channelDescription: _updatesDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
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

  final shown = <(String, String)>[];
  String? updatesChannel;

  @override
  Future<void> prepareUpdatesChannel({
    required String name,
    required String description,
  }) async => updatesChannel = name;

  @override
  Future<void> showUpdate({
    required String title,
    required String body,
    String? payload,
  }) async => shown.add((title, body));
}
