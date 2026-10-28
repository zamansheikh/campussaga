import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/transport_store.dart';

class BusState extends Equatable {
  const BusState({
    this.routes,
    this.myStops = const {},
    this.loading = false,
    this.offline = false,
    this.failure,
  });

  /// Null until loaded (from the phone or the server).
  final BusRoutes? routes;
  final Map<String, String> myStops;
  final bool loading;

  /// Showing the saved copy: the server couldn't be reached.
  final bool offline;
  final Failure? failure;

  BusRoute? route(String id) =>
      routes?.routes.where((r) => r.id == id).firstOrNull;

  BusState copyWith({
    BusRoutes? routes,
    Map<String, String>? myStops,
    bool? loading,
    bool? offline,
    Failure? Function()? failure,
  }) => BusState(
    routes: routes ?? this.routes,
    myStops: myStops ?? this.myStops,
    loading: loading ?? this.loading,
    offline: offline ?? this.offline,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [routes, myStops, loading, offline, failure];
}

/// The student's university bus routes: the saved copy first, then the
/// server; transport reps' edits go through here too.
class BusCubit extends Cubit<BusState> {
  BusCubit(this._repo, this._store) : super(const BusState());

  final TransportRepository _repo;
  final TransportStore _store;
  String? _user;

  /// Opens for [userId] (another account starts empty).
  Future<void> open(String userId) async {
    if (_user != userId) {
      _user = userId;
      emit(const BusState());
      final saved = await _store.routes(userId);
      final stops = await _store.myStops(userId);
      if (isClosed || _user != userId) return;
      emit(state.copyWith(routes: saved, myStops: stops));
    }
    await refresh();
  }

  Future<void> refresh() async {
    final user = _user;
    if (user == null) return;
    emit(state.copyWith(loading: true, failure: () => null));
    try {
      final routes = await _repo.routes();
      if (isClosed || _user != user) return;
      emit(state.copyWith(routes: routes, loading: false, offline: false));
      await _store.saveRoutes(user, routes);
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          offline: f is NetworkFailure && state.routes != null,
          failure: () => f,
        ),
      );
    }
  }

  Future<void> setMyStop(String routeId, String? stopId) async {
    final stops = Map.of(state.myStops);
    if (stopId == null) {
      stops.remove(routeId);
    } else {
      stops[routeId] = stopId;
    }
    emit(state.copyWith(myStops: stops));
    final user = _user;
    if (user != null) await _store.saveMyStops(user, stops);
  }

  void _replace(BusRoute r) {
    final all = state.routes ?? const BusRoutes(canEdit: true);
    final list = [
      for (final x in all.routes)
        if (x.id != r.id) x,
      r,
    ]..sort((a, b) => a.name.compareTo(b.name));
    final next = BusRoutes(routes: list, canEdit: all.canEdit);
    emit(state.copyWith(routes: next));
    final user = _user;
    if (user != null) _store.saveRoutes(user, next);
  }

  // Edits (transport reps): each throws a Failure for the page to show.

  Future<BusRoute> saveRoute({
    String? id,
    required String name,
    required String color,
    String notes = '',
    bool active = true,
  }) async {
    final r = id == null
        ? await _repo.createRoute(
            name: name,
            color: color,
            notes: notes,
            active: active,
          )
        : await _repo.updateRoute(
            id,
            name: name,
            color: color,
            notes: notes,
            active: active,
          );
    _replace(r);
    return r;
  }

  Future<void> deleteRoute(String id) async {
    await _repo.deleteRoute(id);
    final all = state.routes;
    if (all == null) return;
    final next = BusRoutes(
      routes: [
        for (final r in all.routes)
          if (r.id != id) r,
      ],
      canEdit: all.canEdit,
    );
    emit(state.copyWith(routes: next));
    final user = _user;
    if (user != null) await _store.saveRoutes(user, next);
  }

  Future<void> setStops(String id, List<BusStop> stops) async =>
      _replace(await _repo.setStops(id, stops));

  Future<void> setTrips(String id, List<BusTrip> trips) async =>
      _replace(await _repo.setTrips(id, trips));
}
