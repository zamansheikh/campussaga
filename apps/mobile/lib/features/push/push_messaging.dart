import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A push notification as the app sees it.
class PushNote {
  const PushNote({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// From the server: type ('change' | 'announcement') and groupId.
  final Map<String, Object?> data;

  String? get groupId => data['groupId'] as String?;
}

/// Firebase Cloud Messaging, behind an interface so tests can replace it.
abstract interface class PushMessaging {
  /// 'android' or 'ios'.
  String get platform;

  /// This install's token, or null when push isn't available (an iPhone
  /// before the APNs key is set up, no Google Play services, ...).
  Future<String?> token();

  Stream<String> get tokenRefresh;

  /// Arrived while the app is open (the phone doesn't show these itself).
  Stream<PushNote> get foreground;

  /// Tapped while the app was in the background.
  Stream<PushNote> get opened;

  /// Tapped while the app was closed (it opened the app).
  Future<PushNote?> initial();

  /// Asks to show notifications (Android 13+, iOS), once per install: a
  /// "no" is not asked again. Without it the phone receives pushes but
  /// never shows them.
  Future<void> askPermissionOnce();
}

class FirebasePushMessaging implements PushMessaging {
  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  // getToken/onTokenRefresh are deprecated in favour of register() and
  // onRegistered, which return a Firebase Installation ID. The server's FCM
  // HTTP v1 send documents registration tokens, so keep those until the
  // new ID is confirmed to work there.
  @override
  Future<String?> token() async {
    try {
      // ignore: deprecated_member_use
      return await _fm.getToken();
    } on Object {
      return null; // e.g. iOS without APNs yet: no push, nothing breaks
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushNote> get foreground => FirebaseMessaging.onMessage.map(_note);

  @override
  Stream<PushNote> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(_note);

  @override
  Future<PushNote?> initial() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _note(m);
  }

  static const _askedKey = 'push.permissionAsked';

  @override
  Future<void> askPermissionOnce() async {
    try {
      final prefs = SharedPreferencesAsync();
      if (await prefs.getBool(_askedKey) ?? false) return;
      await prefs.setBool(_askedKey, true);
      await _fm.requestPermission();
    } on Object {
      // No permission UI here (or storage failed): pushes stay silent.
    }
  }

  static PushNote _note(RemoteMessage m) => PushNote(
    title: m.notification?.title,
    body: m.notification?.body,
    data: m.data,
  );
}

/// In-memory push (tests): add to the controllers to simulate pushes.
class MemoryPushMessaging implements PushMessaging {
  String? currentToken = 'push-token-1';
  final refresh = StreamController<String>.broadcast();
  final foregroundNotes = StreamController<PushNote>.broadcast();
  final openedNotes = StreamController<PushNote>.broadcast();
  PushNote? initialNote;

  @override
  String get platform => 'android';

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefresh => refresh.stream;

  @override
  Stream<PushNote> get foreground => foregroundNotes.stream;

  @override
  Stream<PushNote> get opened => openedNotes.stream;

  @override
  Future<PushNote?> initial() async {
    final n = initialNote;
    initialNote = null;
    return n;
  }

  int permissionAsks = 0;

  @override
  Future<void> askPermissionOnce() async => permissionAsks++;
}
