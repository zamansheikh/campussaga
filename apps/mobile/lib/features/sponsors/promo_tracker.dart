import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:flutter/widgets.dart';

/// Collects what students do with ads and sends it in small batches.
/// No timers: views wait for a natural moment (10 of them, any tap / copy /
/// hide, a new ad request, or the app going to the background). Lost
/// events are fine.
class PromoTracker with WidgetsBindingObserver {
  PromoTracker(this._repo) {
    WidgetsBinding.instance.addObserver(this);
  }

  final SponsorsRepository _repo;
  final _queue = <PromoEvent>[];
  bool _sending = false;

  /// Views logged in this app session, so each ad counts once per visit of
  /// a screen even if it scrolls in and out.
  final _seen = <String>{};

  /// Logs [type] for [promoId]. A view is only kept once per [visit] (a
  /// screen visit key); taps, copies and hides go out at once.
  void log(String promoId, PromoEventType type, {Object? visit}) {
    if (type == PromoEventType.view) {
      if (!_seen.add('$promoId|${visit.hashCode}')) return;
    }
    _queue.add(PromoEvent(promoId: promoId, type: type, at: DateTime.now()));
    if (type != PromoEventType.view || _queue.length >= 10) unawaited(flush());
  }

  /// Sends what's waiting (at most 50 a call).
  Future<void> flush() async {
    if (_sending || _queue.isEmpty) return;
    _sending = true;
    final batch = _queue.take(50).toList();
    _queue.removeRange(0, batch.length);
    try {
      await _repo.sendEvents(batch);
    } on Failure {
      // Only counts: drop them.
    } finally {
      _sending = false;
    }
    if (_queue.isNotEmpty) await flush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(flush());
    }
  }
}
