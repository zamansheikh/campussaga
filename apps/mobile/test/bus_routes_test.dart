import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/app/di.dart';
import 'package:campussaga/features/transport/data/transport_store.dart';
import 'package:campussaga/features/transport/presentation/bus_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// In-memory bus routes for one university.
class FakeTransportRepository implements TransportRepository {
  FakeTransportRepository({this.canEdit = false, List<BusRoute>? routes})
    : list = [...?routes];

  bool canEdit;
  final List<BusRoute> list;
  Failure? fail;
  var _ids = 0;

  BusRoute _put(BusRoute r) {
    list
      ..removeWhere((x) => x.id == r.id)
      ..add(r);
    return r;
  }

  BusRoute _get(String id) => list.firstWhere(
    (r) => r.id == id,
    orElse: () => throw const NotFoundFailure(code: 'ROUTE_NOT_FOUND'),
  );

  @override
  Future<BusRoutes> routes() async {
    if (fail case final f?) throw f;
    return BusRoutes(routes: [...list], canEdit: canEdit);
  }

  @override
  Future<BusRoute> createRoute({
    required String name,
    String color = '#0F766E',
    String notes = '',
    bool active = true,
  }) async => _put(
    BusRoute(
      id: 'r${++_ids}',
      name: name,
      color: color,
      notes: notes,
      active: active,
    ),
  );

  @override
  Future<BusRoute> updateRoute(
    String id, {
    required String name,
    String color = '#0F766E',
    String notes = '',
    bool active = true,
  }) async {
    final r = _get(id);
    return _put(
      BusRoute(
        id: id,
        name: name,
        color: color,
        notes: notes,
        active: active,
        stops: r.stops,
        trips: r.trips,
      ),
    );
  }

  @override
  Future<void> deleteRoute(String id) async =>
      list.removeWhere((r) => r.id == id);

  @override
  Future<BusRoute> setStops(String id, List<BusStop> stops) async {
    final r = _get(id);
    return _put(
      BusRoute(
        id: id,
        name: r.name,
        color: r.color,
        notes: r.notes,
        active: r.active,
        stops: [
          for (final s in stops)
            BusStop(
              id: s.id.isEmpty ? '$id-s${++_ids}' : s.id,
              name: s.name,
              landmark: s.landmark,
              toCampusMin: s.toCampusMin,
              fromCampusMin: s.fromCampusMin,
            ),
        ],
        trips: r.trips,
      ),
    );
  }

  @override
  Future<BusRoute> setTrips(String id, List<BusTrip> trips) async {
    final r = _get(id);
    return _put(
      BusRoute(
        id: id,
        name: r.name,
        color: r.color,
        notes: r.notes,
        active: r.active,
        stops: r.stops,
        trips: [
          for (final t in trips)
            BusTrip(
              id: t.id.isEmpty ? '$id-t${++_ids}' : t.id,
              direction: t.direction,
              departsMin: t.departsMin,
              weekdays: t.weekdays,
              note: t.note,
            ),
        ],
      ),
    );
  }
}

const _satToThu = {6, 7, 1, 2, 3, 4};

const mirpur = BusRoute(
  id: 'mirpur',
  name: 'Mirpur',
  stops: [
    BusStop(id: 'm10', name: 'Mirpur 10', toCampusMin: 0, fromCampusMin: 40),
    BusStop(
      id: 'aga',
      name: 'Agargaon',
      landmark: 'IDB Bhaban',
      toCampusMin: 15,
      fromCampusMin: 25,
    ),
    BusStop(id: 'cam', name: 'Campus', toCampusMin: 40, fromCampusMin: 0),
  ],
  trips: [
    BusTrip(
      id: 't1',
      direction: BusDirection.toCampus,
      departsMin: 7 * 60 + 30,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 't2',
      direction: BusDirection.toCampus,
      departsMin: 8 * 60 + 30,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 't3',
      direction: BusDirection.fromCampus,
      departsMin: 17 * 60,
      weekdays: _satToThu,
    ),
  ],
);

/// Registers the app fakes plus bus routes; returns the bus repository.
Future<(FakeTransportRepository, MemoryTransportStore)> _setUp({
  bool canEdit = false,
  List<BusRoute> routes = const [mirpur],
}) async {
  final (auth, _) = await registerFakes();
  auth.savedUser = testUser;
  final repo = FakeTransportRepository(canEdit: canEdit, routes: routes);
  final store = MemoryTransportStore();
  getIt
    ..registerSingleton<TransportRepository>(repo)
    ..registerSingleton<TransportStore>(store)
    ..registerSingleton<BusCubit>(BusCubit(repo, store));
  return (repo, store);
}

Future<void> _openBus(WidgetTester tester) async {
  await tester.pumpWidget(const CampusApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Explore'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bus routes'));
  await tester.pumpAndSettle();
}

void main() {
  // Tuesday 8:05 AM: the 8:30 bus is next.
  setUp(() => appNow = () => DateTime(2026, 10, 27, 8, 5));
  tearDown(() => appNow = DateTime.now);

  testWidgets('a student finds the next bus from their stop', (tester) async {
    usePhoneScreen(tester);
    final (_, store) = await _setUp();
    await _openBus(tester);

    // The list: each route with its next bus.
    expect(find.text('Mirpur'), findsOneWidget);
    expect(find.text('Mirpur 10 → Campus'), findsOneWidget);
    expect(find.textContaining('Next: 8:30'), findsOneWidget);
    expect(find.text('Add route'), findsNothing); // not a transport rep

    // The route: stops with this trip's times.
    await tester.tap(find.text('Mirpur'));
    await tester.pumpAndSettle();
    expect(find.text('Agargaon'), findsOneWidget);
    expect(find.text('IDB Bhaban'), findsOneWidget);
    expect(find.textContaining('8:45'), findsOneWidget); // 8:30 + 15 min

    // Pick a stop: the next buses from there.
    await tester.tap(find.text('Pick your stop to see your next bus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agargaon').last);
    await tester.pumpAndSettle();
    expect(find.text('Next bus from Agargaon'), findsOneWidget);
    expect(find.text('in 40 min'), findsOneWidget);
    expect(store.stops['u1'], {'mirpur': 'aga'});

    // The way back.
    await tester.tap(find.text('From campus'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5:25'), findsWidgets); // 5:00 PM + 25 min
    await tester.scrollUntilVisible(find.text('DEPARTURES'), 200);
    expect(find.text('Sat–Thu · From Campus'), findsOneWidget);

    // Back on the list, the card follows my stop.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Next bus from Agargaon'), findsOneWidget);
  });

  testWidgets('saved routes open offline', (tester) async {
    usePhoneScreen(tester);
    final (repo, store) = await _setUp();
    store.saved['u1'] = const BusRoutes(routes: [mirpur]);
    repo.fail = const NetworkFailure();
    await _openBus(tester);

    expect(find.text('Mirpur'), findsOneWidget);
    expect(find.text('Offline. Showing saved bus routes.'), findsOneWidget);
  });

  testWidgets('a transport rep adds a route, its stops and a departure', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final (repo, _) = await _setUp(canEdit: true, routes: []);
    await _openBus(tester);

    expect(find.text('No bus routes yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add route'));
    await tester.pumpAndSettle();

    // Name is required.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Give it a name.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Uttara');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.list.single.name, 'Uttara');

    // Lands on the new route; add two stops.
    expect(find.text('Uttara'), findsOneWidget);
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit stops'));
    await tester.pumpAndSettle();
    for (final (name, mins) in [('House Building', '0'), ('Campus', '35')]) {
      await tester.tap(find.text('Add stop'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), name);
      await tester.enterText(fields.at(2), mins);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    }
    expect(find.text('House Building'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repo.list.single.stops.map((s) => s.name), [
      'House Building',
      'Campus',
    ]);

    // Add a departure (7:30 AM, Sat–Thu by default).
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit timetable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add departure'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Sat–Thu'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final trip = repo.list.single.trips.single;
    expect(trip.departsMin, 7 * 60 + 30);
    expect(trip.weekdays, _satToThu);

    // Back on the route: the departure is listed.
    await tester.scrollUntilVisible(find.text('DEPARTURES'), 200);
    expect(find.text('Sat–Thu · From House Building'), findsOneWidget);
  });
}
