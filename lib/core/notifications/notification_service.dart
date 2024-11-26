import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
//donwload file -- add this to your file
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  // Singleton Pattern
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> init() async {
    // Android Initialization Settings
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization Settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    // Combine Platform-Specific Initialization Settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin and setup callback handlers
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationResponseHandler,
      onDidReceiveBackgroundNotificationResponse:
          backgroundNotificationResponseHandler,
    );

    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();

    // Request notification permissions (Android-specific)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Show an immediate notification
  Future<void> showNotificationNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android Notification Details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'basic_channel',
      'Important Notices',
      channelDescription: 'This channel is used for important notices',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    // iOS Notification Details
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    // Combine Platform-Specific Notification Details
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Show Notification
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload, // Attach a payload
    );
  }

  /// Schedule a notification for a future time
  Future<void> showNotificationScheduled({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Android Notification Details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'basic_channel',
      'Important Notices',
      channelDescription: 'This channel is used for important notices',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    // iOS Notification Details
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    // Combine Platform-Specific Notification Details
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule Notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      payload: payload, // Attach a payload
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Show a notification with an image URL
  Future<void> showNotificationWithImage({
    required int id,
    required String title,
    required String body,
    required String imageUrl,
    String? payload,
  }) async {
    try {
      // Download and save the image file
      final String filePath =
          await downloadAndSaveFile(imageUrl, 'notification_image_$id.jpg');

      // Android-specific Big Picture Style
      final BigPictureStyleInformation bigPictureStyleInformation =
          BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath), // Image file path for notification
        largeIcon: FilePathAndroidBitmap(filePath), // Optional large icon
        contentTitle: title,
        summaryText: body,
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      );

      // Android Notification Details with Big Picture Style
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'image_channel',
        'Image Notifications',
        channelDescription: 'Channel for notifications with images',
        styleInformation: bigPictureStyleInformation,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      // iOS Notification Details (without image support directly in notification)
      final DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      // Combine Platform-Specific Notification Details
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Show Notification
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload, // Attach a payload
      );
    } catch (e) {
      print('Error showing notification with image: $e');
    }
  }

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}

/// Download and save a file to the device
Future<String> downloadAndSaveFile(String url, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final response = await http.get(Uri.parse(url));
  final file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

/// Background notification response handler
void backgroundNotificationResponseHandler(NotificationResponse response) {
  if (response.payload != null) {
    // Handle the notification payload
    print("Notification payload received: ${response.payload}");
    handleNotificationPayload(response.payload!);
  }
}

/// Notification response handler
void notificationResponseHandler(NotificationResponse response) {
  if (response.payload != null) {
    print("Notification payload received: ${response.payload}");
    handleNotificationPayload(response.payload!);
  }
}

/// Handle actions based on notification payload
void handleNotificationPayload(String payload) {
  // Example: Log payload or navigate to specific screen
  print("Notification payload received: $payload");

  // Add custom logic here, such as navigation:
  if (payload == 'navigate_to_detail_screen') {
    // Example:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen()));
  }
}
