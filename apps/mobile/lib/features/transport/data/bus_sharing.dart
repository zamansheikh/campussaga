import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/clock.dart';
import 'my_location.dart';

enum BusShareStatus { idle, starting, sharing }

/// A sharing session that ended: what to thank the student for and which
/// trip to ask about.
class BusShareEnded extends Equatable {
  const BusShareEnded({
    required this.routeId,
    required this.direction,
    required this.departsMin,
    required this.day,
    required this.reason,
    this.thanks,
  });

  final String routeId;
  final BusDirection direction;
  final int? departsMin;

  /// The day the trip departed.
  final DateTime day;
  final BusShareEnd reason;
  final BusShareThanks? thanks;

  @override
  List<Object?> get props => [
    routeId,
    direction,
    departsMin,
    day,
    reason,
    thanks?.helped,
    thanks?.trips,
  ];
}

class BusShareState extends Equatable {
  const BusShareState({
    this.status = BusShareStatus.idle,
    this.routeId,
    this.direction,
    this.departsMin,
    this.day,
    this.sessionId,
    this.riders = 1,
    this.startedAt,
    this.lastSentAt,
    this.queued = 0,
    this.offline = false,
    this.ended,
  });

  final BusShareStatus status;
  final String? routeId;
  final BusDirection? direction;
  final int? departsMin;
  final DateTime? day;
  final String? sessionId;

  /// Students sharing from this bus, me included.
  final int riders;
  final DateTime? startedAt;
  final DateTime? lastSentAt;

  /// Points waiting to be sent (offline).
  final int queued;
  final bool offline;

  /// The last session that ended, until the route page has shown it.
  final BusShareEnded? ended;

  bool get active => status != BusShareStatus.idle;

  bool sharing(String routeId) => active && this.routeId == routeId;

  @override
  List<Object?> get props => [
    status,
    routeId,
    direction,
    departsMin,
    day,
    sessionId,
    riders,
    startedAt,
    lastSentAt,
    queued,
    offline,
    ended,
  ];
}

/// Why sharing couldn't start.
sealed class BusShareProblem {
  const BusShareProblem();
}

class BusShareNoLocation extends BusShareProblem {
  const BusShareNoLocation(this.problem);
  final LocationProblem problem;
}

class BusShareRefused extends BusShareProblem {
  const BusShareRefused(this.failure);
  final Failure failure;
}

/// The words of the ongoing notification.
typedef BusShareNotice = ({String title, String text, String channel});

/// Shares the bus's location while the student is on it: points every
/// ~10 s, sent in batches, held while offline; ends on Stop, when the
/// server says the bus arrived (or the session is over), or after
/// [maxDuration]. One session at a time, app-wide.
class BusSharing extends Cubit<BusShareState> {
  BusSharing(
    this._repo, {
    this.flushEvery = const Duration(seconds: 15),
    this.maxDuration = const Duration(hours: 3),
  }) : super(const BusShareState());

  final BusLiveRepository _repo;
  final Duration flushEvery;
  final Duration maxDuration;

  /// At most this many points per request, and held while offline.
  static const batch = 30;
  static const maxQueued = 240;

  final _queue = <BusPoint>[];
  StreamSubscription<Position>? _sub;
  Timer? _flushTimer;
  Timer? _deadline;
  bool _sending = false;

  static BusPoint _point(Position p) => BusPoint(
    at: p.timestamp,
    lat: p.latitude,
    lng: p.longitude,
    accuracy: p.accuracy,
    speed: p.speed,
    heading: p.heading,
  );

  /// Starts sharing [route] on the trip leaving at [departsMin] (null: a
  /// bus not on the timetable) on [day]. Null when it started.
  Future<BusShareProblem?> start(
    BusRoute route, {
    required BusDirection direction,
    required int? departsMin,
    required DateTime day,
    required BusShareNotice notice,
  }) async {
    if (state.active) await stop();
    emit(BusShareState(status: BusShareStatus.starting, routeId: route.id));
    final here = await MyLocation.instance.current();
    final pos = here.position;
    if (pos == null) {
      emit(const BusShareState());
      return BusShareNoLocation(here.problem ?? LocationProblem.serviceOff);
    }
    final String session;
    try {
      session = (await _repo.startSharing(
        route.id,
        direction: direction,
        departsMin: departsMin,
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
      )).sessionId;
    } on Failure catch (f) {
      emit(const BusShareState());
      return BusShareRefused(f);
    }
    if (isClosed) return null;
    _queue
      ..clear()
      ..add(_point(pos));
    final now = appNow();
    emit(
      BusShareState(
        status: BusShareStatus.sharing,
        routeId: route.id,
        direction: direction,
        departsMin: departsMin,
        day: DateTime(day.year, day.month, day.day),
        sessionId: session,
        startedAt: now,
        queued: _queue.length,
      ),
    );
    _sub = MyLocation.instance
        .sharing(
          title: notice.title,
          text: notice.text,
          channel: notice.channel,
        )
        .listen(_onPosition, onError: (Object _) => unawaited(stop()));
    _flushTimer = Timer.periodic(flushEvery, (_) => unawaited(flush()));
    _deadline = Timer(
      maxDuration,
      () => unawaited(_finish(BusShareEnd.expired)),
    );
    return null;
  }

  void _onPosition(Position p) {
    if (state.status != BusShareStatus.sharing) return;
    _queue.add(_point(p));
    if (_queue.length > maxQueued) {
      _queue.removeRange(0, _queue.length - maxQueued);
    }
    emit(_copy(queued: _queue.length));
  }

  BusShareState _copy({
    int? riders,
    DateTime? lastSentAt,
    int? queued,
    bool? offline,
    bool keepEnded = true,
  }) => BusShareState(
    status: state.status,
    routeId: state.routeId,
    direction: state.direction,
    departsMin: state.departsMin,
    day: state.day,
    sessionId: state.sessionId,
    riders: riders ?? state.riders,
    startedAt: state.startedAt,
    lastSentAt: lastSentAt ?? state.lastSentAt,
    queued: queued ?? state.queued,
    offline: offline ?? state.offline,
    ended: keepEnded ? state.ended : null,
  );

  /// Sends what's waiting (also on a timer).
  Future<void> flush() async {
    final session = state.sessionId;
    if (_sending || session == null || _queue.isEmpty) return;
    _sending = true;
    final sent = _queue.take(batch).toList();
    try {
      final r = await _repo.ping(session, sent);
      if (isClosed || state.sessionId != session) return;
      _queue.removeRange(0, sent.length);
      emit(
        _copy(
          riders: r.riders,
          lastSentAt: appNow(),
          queued: _queue.length,
          offline: false,
        ),
      );
      if (r.ended) {
        await _finish(r.reason ?? BusShareEnd.expired);
      } else if (_queue.length >= batch) {
        _sending = false;
        await flush();
      }
    } on NetworkFailure {
      if (!isClosed && state.sessionId == session) emit(_copy(offline: true));
    } on Failure catch (f) {
      if (isClosed || state.sessionId != session) return;
      if (f.code == 'SESSION_NOT_FOUND') {
        await _finish(BusShareEnd.expired);
      } else {
        _queue.removeRange(0, sent.length); // refused: don't send it again
        emit(_copy(queued: _queue.length));
      }
    } finally {
      _sending = false;
    }
  }

  /// The student stops sharing.
  Future<void> stop() async {
    if (!state.active) return;
    if (state.status == BusShareStatus.sharing) await flush();
    await _finish(BusShareEnd.stopped);
  }

  Future<void> _finish(BusShareEnd reason) async {
    final s = state;
    final session = s.sessionId;
    _stopTracking();
    // Nothing more goes out from here on.
    emit(const BusShareState());
    if (session == null || s.routeId == null) return;
    BusShareThanks? thanks;
    try {
      thanks = await _repo.stopSharing(session);
    } on Failure {
      thanks = null; // offline: still say thanks, without the numbers
    }
    if (isClosed || state.active) return;
    emit(
      BusShareState(
        ended: BusShareEnded(
          routeId: s.routeId!,
          direction: s.direction!,
          departsMin: s.departsMin,
          day: s.day!,
          reason: reason,
          thanks: thanks,
        ),
      ),
    );
  }

  /// The route page showed the end of the last session.
  void seenEnded() {
    if (state.ended != null) emit(_copy(keepEnded: false));
  }

  void _stopTracking() {
    unawaited(_sub?.cancel());
    _sub = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _deadline?.cancel();
    _deadline = null;
    _queue.clear();
  }

  @override
  Future<void> close() {
    _stopTracking();
    return super.close();
  }
}
