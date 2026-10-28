import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/env.dart';

/// Group invites as links: https://varsitykotha.com/join/ABCDEF opens the
/// app on the join screen (Android app link), or the web page with the code
/// and a Google Play button. Installing from that button passes the code to
/// the Play install referrer, so the new app offers to join straight away.
abstract final class InviteLink {
  static final _code = RegExp(r'^[A-HJ-NP-Z]{6}$');

  /// The link classmates open.
  static Uri link(String code) => Uri.parse('${Env.siteUrl}/join/$code');

  /// [s] as a join code, or null.
  static String? code(String? s) {
    final c = s?.trim().toUpperCase();
    return c != null && _code.hasMatch(c) ? c : null;
  }

  /// The code in a Play install referrer such as "utm_source=invite&join=ABCDEF".
  static String? fromReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    try {
      return code(Uri.splitQueryString(referrer)['join']);
    } on FormatException {
      return null;
    }
  }
}

/// A join code waiting for the student to sign in (from a link, or from
/// installing through an invite). Kept on the phone until used.
abstract final class PendingInvite {
  static const _key = 'pending_invite';
  static const _checkedKey = 'install_referrer_checked';
  static String? _code;

  /// The waiting code, if any.
  static String? get code => _code;

  static Future<void> load() async {
    try {
      _code = (await SharedPreferences.getInstance()).getString(_key);
    } on Object {
      _code = null;
    }
  }

  static void save(String code) {
    _code = code;
    _persist((p) => p.setString(_key, code));
  }

  /// The code, once: it's forgotten as it's used.
  static String? take() {
    final c = _code;
    if (c == null) return null;
    _code = null;
    _persist((p) => p.remove(_key));
    return c;
  }

  /// Writes in the background; the in-memory code is what counts now.
  static void _persist(Future<bool> Function(SharedPreferences) f) {
    SharedPreferences.getInstance().then(f).catchError((Object _) => false);
  }

  /// First start after installing from an invite: keep its code. Asked
  /// once per install; quiet on errors (sideloaded builds, no Play).
  static Future<void> checkInstallReferrer() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_checkedKey) ?? false) return;
      await prefs.setBool(_checkedKey, true);
      final details = await PlayInstallReferrer.installReferrer;
      final c = InviteLink.fromReferrer(details.installReferrer);
      if (c != null) save(c);
    } on Object {
      // No referrer: nothing to do.
    }
  }
}
