import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/app/di.dart';
import 'package:varsitykotha/features/transport/data/transport_store.dart';
import 'package:varsitykotha/features/transport/presentation/bus_cubit.dart';

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
    String driverName = '',
    String driverPhone = '',
  }) async => _put(
    BusRoute(
      id: 'r${++_ids}',
      name: name,
      color: color,
      notes: notes,
      active: active,
      driverName: driverName,
      driverPhone: driverPhone,
    ),
  );

  @override
  Future<BusRoute> updateRoute(
    String id, {
    required String name,
    String color = '#0F766E',
    String notes = '',
    bool active = true,
    String driverName = '',
    String driverPhone = '',
  }) async {
    final r = _get(id);
    return _put(
      BusRoute(
        id: id,
        name: name,
        color: color,
        notes: notes,
        active: active,
        driverName: driverName,
        driverPhone: driverPhone,
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
        driverName: r.driverName,
        driverPhone: r.driverPhone,
        stops: [
          for (final s in stops)
            BusStop(
              id: s.id.isEmpty ? '$id-s${++_ids}' : s.id,
              name: s.name,
              landmark: s.landmark,
              toCampusMin: s.toCampusMin,
              fromCampusMin: s.fromCampusMin,
              lat: s.lat,
              lng: s.lng,
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
        driverName: r.driverName,
        driverPhone: r.driverPhone,
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
    expect(find.text('Mirpur 10 → Campus · 3 stops'), findsOneWidget);
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

  testWidgets('a transport rep sets up a route: stops, then times', (
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

    // Straight into the stops: type one, press Enter, type the next.
    expect(find.text('Edit stops'), findsOneWidget);
    final quick = find.widgetWithText(TextField, 'Type a stop and press Enter');
    for (final name in ['House Building', 'Campus']) {
      await tester.enterText(quick, name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    expect(find.text('House Building'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    // Campus is 35 minutes from House Building.
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Minutes from House Building'),
      '35',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('+35 min'), findsOneWidget);
    expect(find.text('35 min to campus'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final stops = repo.list.single.stops;
    expect(stops.map((s) => s.name), ['House Building', 'Campus']);
    expect(stops.map((s) => s.toCampusMin), [0, 35]);
    expect(stops.map((s) => s.fromCampusMin), [35, 0], reason: 'mirrored');

    // Then on to the times: two at once (7:30 and 8:00), Sat–Thu.
    expect(find.text('Edit timetable'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add times').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('7:30'), findsOneWidget);
    await tester.tap(find.text('Add another time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // the time picker's suggestion: 8:00
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add 2 departures'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final trips = repo.list.single.trips;
    expect(trips.map((t) => t.departsMin), [7 * 60 + 30, 8 * 60]);
    expect(trips.first.weekdays, _satToThu);

    // Back on the route: set up, so no guide; the departures are listed.
    expect(find.text('Finish setting up this route'), findsNothing);
    await tester.scrollUntilVisible(find.text('DEPARTURES'), 200);
    expect(find.text('Sat–Thu · From House Building'), findsNWidgets(2));
  });

  testWidgets('a rep pastes a notice\'s stops, and undoes a removal', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final (repo, _) = await _setUp(
      canEdit: true,
      routes: [const BusRoute(id: 'r', name: 'PMSCS')],
    );
    await _openBus(tester);
    await tester.tap(find.text('PMSCS'));
    await tester.pumpAndSettle();

    // A route with nothing yet shows the setup guide.
    expect(find.text('Finish setting up this route'), findsOneWidget);
    await tester.tap(find.text('Add the stops'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Paste a list'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      'Mohakhali (under the flyover), Agargaon, Gabtoli--- Campus.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add 4 stops'));
    await tester.pumpAndSettle();
    expect(find.text('under the flyover'), findsOneWidget);

    // Swipe one away, then undo.
    await tester.drag(find.text('Agargaon'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Agargaon removed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Agargaon'), findsOneWidget);

    // Leaving without saving asks first.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final stops = repo.list.single.stops;
    expect(stops.map((s) => s.name), [
      'Mohakhali',
      'Agargaon',
      'Gabtoli',
      'Campus',
    ]);
    expect(stops.first.landmark, 'under the flyover');
    // Only the first stop has a time going (no minutes given yet).
    expect(stops.map((s) => s.toCampusMin), [0, null, null, null]);
  });

  testWidgets('a stop with no time listed says when the bus leaves', (
    tester,
  ) async {
    usePhoneScreen(tester);
    const route = BusRoute(
      id: 'p',
      name: 'PMSCS 1',
      stops: [
        BusStop(id: 'a', name: 'Abdullahpur', toCampusMin: 0),
        BusStop(id: 'b', name: 'Banani'),
        BusStop(id: 'c', name: 'Campus', fromCampusMin: 0),
      ],
      trips: [
        BusTrip(
          direction: BusDirection.toCampus,
          departsMin: 8 * 60 + 40,
          weekdays: _satToThu,
        ),
      ],
    );
    final (_, store) = await _setUp(routes: [route]);
    store.stops['u1'] = {'p': 'b'};
    await _openBus(tester);
    await tester.tap(find.text('PMSCS 1'));
    await tester.pumpAndSettle();

    final card = find.textContaining('Banani has no time listed.');
    expect(card, findsOneWidget);
    final text = tester.widget<Text>(card).data!;
    expect(text, contains('The bus leaves Abdullahpur at 8:40'));
    expect(text, endsWith('(in 35 min)'));
    await tester.tap(find.text('From campus'));
    await tester.pumpAndSettle();
    expect(find.text('No buses from campus on this route.'), findsOneWidget);
  });

  testWidgets('a rep adds the driver; students see a call button', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final (repo, _) = await _setUp(canEdit: true);
    await _openBus(tester);
    await tester.tap(find.text('Mirpur'));
    await tester.pumpAndSettle();
    expect(find.text('Call driver'), findsNothing);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit route'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, "Driver's name (optional)"),
      'Parvez',
    );
    final phone = find.widgetWithText(TextField, "Driver's phone (optional)");
    await tester.enterText(phone, 'call me');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Use a phone number like 01712345678.'), findsOneWidget);
    await tester.enterText(phone, '০১৯৮৯ ১৫৫৬১৪');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final r = repo.list.single;
    expect(r.driverName, 'Parvez');
    expect(r.driverPhone, '01989155614');
    expect(r.stops, isNotEmpty, reason: 'editing the route keeps its stops');
    expect(find.text('Parvez'), findsOneWidget);
    expect(find.text('Driver · 01989155614'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Call driver'), findsOneWidget);
  });
}
