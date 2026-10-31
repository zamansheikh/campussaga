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

  /// The link classmates open. [ref] is the sharer's own invite code: it
  /// rides along (`?ref=`) so a friend who joins counts as their invite.
  static Uri link(String code, {String? ref}) {
    final r = referralCode(ref);
    return Uri.parse('${Env.siteUrl}/join/$code${r == null ? '' : '?ref=$r'}');
  }

  static final _ref = RegExp(r'^[a-z0-9]{8}$');

  /// [s] as a personal invite code (8 letters and digits), or null.
  static String? referralCode(String? s) {
    final c = s?.trim().toLowerCase();
    return c != null && _ref.hasMatch(c) ? c : null;
  }

  /// A student's personal invite link (https://varsitykotha.com/r/{code}).
  static Uri personalLink(String ref) =>
      Uri.parse('${Env.siteUrl}/r/${referralCode(ref) ?? ref}');

  /// [s] as a join code, or null.
  static String? code(String? s) {
    final c = s?.trim().toUpperCase();
    return c != null && _code.hasMatch(c) ? c : null;
  }

  /// The class code in a Play install referrer such as
  /// "utm_source=invite&join=ABCDEF".
  static String? fromReferrer(String? referrer) => parseReferrer(referrer).join;

  /// Both codes of an install referrer: the class to join (`join=`) and
  /// whose invite brought the student (`ref=`), either or both.
  static ({String? join, String? ref}) parseReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return (join: null, ref: null);
    try {
      final q = Uri.splitQueryString(referrer);
      return (join: code(q['join']), ref: referralCode(q['ref']));
    } on FormatException {
      return (join: null, ref: null);
    }
  }
}

/// Whose invite brought this student, waiting for sign-in: `link` (their
/// personal link) or `join` (a class invite they shared). Claimed once,
/// after sign-in; kept on the phone until then.
abstract final class PendingReferral {
  static const _key = 'pending_referral';
  static ({String code, String source})? _value;

  /// The waiting code and how it came, if any.
  static ({String code, String source})? get value => _value;

  static Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      final parts = raw?.split(':');
      _value = parts != null && parts.length == 2
          ? (code: parts[0], source: parts[1])
          : null;
    } on Object {
      _value = null;
    }
  }

  /// Keeps [code] (a valid invite code) unless one is already waiting.
  static void save(String code, {required String source}) {
    final c = InviteLink.referralCode(code);
    if (c == null || _value != null) return;
    final src = source == 'join' ? 'join' : 'link';
    _value = (code: c, source: src);
    _persist((p) => p.setString(_key, '$c:$src'));
  }

  /// The waiting referral, once: it's forgotten as it's used.
  static ({String code, String source})? take() {
    final v = _value;
    if (v == null) return null;
    _value = null;
    _persist((p) => p.remove(_key));
    return v;
  }

  /// Forgets any waiting referral (tests).
  static void clear() {
    _value = null;
    _persist((p) => p.remove(_key));
  }

  static void _persist(Future<bool> Function(SharedPreferences) f) {
    SharedPreferences.getInstance().then(f).catchError((Object _) => false);
  }

  /// Saves what an install referrer carries: `ref` with `join` came through
  /// a class invite.
  static void saveFromReferrer(String? referrer) {
    final r = InviteLink.parseReferrer(referrer);
    final ref = r.ref;
    if (ref != null) save(ref, source: r.join != null ? 'join' : 'link');
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
      PendingReferral.saveFromReferrer(details.installReferrer);
    } on Object {
      // No referrer: nothing to do.
    }
  }
}
