import 'dart:async';

import 'package:campus_core/campus_core.dart';

import 'push_messaging.dart';

/// Keeps this phone registered for pushes while a student is signed in
/// (with the app language, which picks the notification text), and routes
/// incoming pushes: show them if the app is open, refresh the routine, and
/// open the group when one is tapped.
class PushController {
  PushController(
    this._messaging,
    this._devices, {
    required this.onForeground,
    required this.onOpened,
  });

  final PushMessaging _messaging;
  final DeviceRepository _devices;
  final void Function(PushNote note) onForeground;
  final void Function(PushNote note) onOpened;

  final _subs = <StreamSubscription<Object?>>[];
  bool _signedIn = false;
  String _language = 'en';
  String? _registered; // token|language last sent

  void start() {
    _subs
      ..add(_messaging.tokenRefresh.listen((_) => unawaited(_register())))
      ..add(_messaging.foreground.listen(onForeground))
      ..add(_messaging.opened.listen(onOpened));
  }

  /// A student signed in (or the app opened signed in).
  Future<void> signedIn() async {
    _signedIn = true;
    _registered = null;
    await _register();
    final first = await _messaging.initial();
    if (first != null) onOpened(first);
  }

  /// Signed out: the server already stopped pushes with the session.
  void signedOut() {
    _signedIn = false;
    _registered = null;
  }

  Future<void> setLanguage(String language) async {
    if (language == _language) return;
    _language = language;
    await _register();
  }

  Future<void> _register() async {
    if (!_signedIn) return;
    final token = await _messaging.token();
    if (token == null) return;
    final key = '$token|$_language';
    if (key == _registered) return;
    try {
      await _devices.registerDevice(
        token: token,
        platform: _messaging.platform,
        language: _language,
      );
      _registered = key;
    } on Failure {
      // Offline: retried on the next start, language change or new token.
    }
  }

  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}
