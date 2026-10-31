import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/clock.dart';
import '../data/transport_store.dart';

class BusLiveState extends Equatable {
  const BusLiveState({
    this.live = BusLive.none,
    this.insights = const {},
    this.alerts = const {},
    this.answered = const {},
    this.loaded = false,
  });

  final BusLive live;

  /// By [tripKey].
  final Map<String, BusTripInsight> insights;
  final Map<BusDirection, BusAlert> alerts;

  /// Trips the student rated or waved away ([feedbackKey]).
  final Set<String> answered;
  final bool loaded;

  BusTripInsight? insight(BusTrip t) =>
      insights[tripKey(t.direction, t.departsMin)];

  BusLiveState copyWith({
    BusLive? live,
    Map<String, BusTripInsight>? insights,
    Map<BusDirection, BusAlert>? alerts,
    Set<String>? answered,
    bool? loaded,
  }) => BusLiveState(
    live: live ?? this.live,
    insights: insights ?? this.insights,
    alerts: alerts ?? this.alerts,
    answered: answered ?? this.answered,
    loaded: loaded ?? this.loaded,
  );

  @override
  List<Object?> get props => [live, insights, alerts, answered, loaded];
}

String tripKey(BusDirection d, int departsMin) => '${d.wire}|$departsMin';

/// One trip on one day, for "How was the 7:30 bus?".
String feedbackKey(
  String routeId,
  BusDirection d,
  int departsMin,
  DateTime day,
) => '$routeId|${d.wire}|${_day(day)}|$departsMin';

/// A route on a day: asked about once a day at most.
String feedbackDayKey(String routeId, DateTime day) => '$routeId|${_day(day)}';

String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// A route's live buses (polled while a page shows them), what riders say
/// about its trips, and the student's "bus near" alerts.
class BusLiveCubit extends Cubit<BusLiveState> {
  BusLiveCubit(
    this._repo,
    this._store, {
    required this.routeId,
    required this.userId,
    this.every = const Duration(seconds: 10),
  }) : super(const BusLiveState());

  final BusLiveRepository _repo;
  final TransportStore _store;
  final String routeId;
  final String userId;
  final Duration every;
  Timer? _timer;

  /// Loads everything and keeps the live buses fresh until [pause].
  Future<void> start({bool extras = true}) async {
    resume();
    if (extras) {
      unawaited(_loadExtras());
    }
    await refresh();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    _timer ??= Timer.periodic(every, (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    try {
      final live = await _repo.live(routeId);
      if (!isClosed) emit(state.copyWith(live: live, loaded: true));
    } on Failure {
      // Keep what's shown; a stale bus fades out on its own (updatedAt).
      if (!isClosed) emit(state.copyWith(loaded: true));
    }
  }

  Future<void> _loadExtras() async {
    final answered = await _store.feedbackDone(userId);
    if (!isClosed) emit(state.copyWith(answered: answered));
    try {
      final results = await Future.wait([
        _repo.insights(routeId),
        _repo.alerts(),
      ]);
      if (isClosed) return;
      final insights = results[0] as List<BusTripInsight>;
      final alerts = results[1] as List<BusAlert>;
      emit(
        state.copyWith(
          insights: {
            for (final i in insights) tripKey(i.direction, i.departsMin): i,
          },
          alerts: {
            for (final a in alerts)
              if (a.routeId == routeId) a.direction: a,
          },
        ),
      );
    } on Failure {
      // Insights and alerts are extras; the page works without them.
    }
  }

  /// Turns the "bus near" push on (or changes it). Throws a `Failure`.
  Future<void> setAlert({
    required String stopId,
    required BusDirection direction,
    required int leadMin,
  }) async {
    final a = await _repo.setAlert(
      routeId,
      stopId: stopId,
      direction: direction,
      leadMin: leadMin,
    );
    if (!isClosed) {
      emit(state.copyWith(alerts: {...state.alerts, direction: a}));
    }
  }

  Future<void> removeAlert(BusDirection direction) async {
    await _repo.removeAlert(routeId, direction);
    if (!isClosed) {
      emit(
        state.copyWith(
          alerts: {
            for (final e in state.alerts.entries)
              if (e.key != direction) e.key: e.value,
          },
        ),
      );
    }
  }

  /// "How was the trip?": sends it (throws a `Failure`) and remembers it.
  Future<void> feedback({
    required BusDirection direction,
    required int departsMin,
    required DateTime day,
    required BusTripStatus status,
    bool crowded = false,
  }) async {
    final insight = await _repo.sendFeedback(
      routeId,
      direction: direction,
      departsMin: departsMin,
      date: day,
      status: status,
      crowded: crowded,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        insights: {
          ...state.insights,
          tripKey(insight.direction, insight.departsMin): insight,
        },
      ),
    );
    await answer(direction, departsMin, day);
  }

  /// Don't ask about this trip again, nor about this route until tomorrow.
  Future<void> answer(BusDirection d, int departsMin, DateTime day) async {
    final next = {
      ...state.answered,
      feedbackKey(routeId, d, departsMin, day),
      feedbackDayKey(routeId, appNow()),
    };
    if (!isClosed) emit(state.copyWith(answered: next));
    await _store.saveFeedbackDone(userId, next);
  }

  @override
  Future<void> close() {
    pause();
    return super.close();
  }
}
