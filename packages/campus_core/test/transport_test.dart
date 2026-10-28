import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

const _route = BusRoute(
  id: 'r1',
  name: 'Route 4',
  stops: [
    BusStop(id: 'a', name: 'Mirpur 10', toCampusMin: 0, fromCampusMin: 50),
    BusStop(id: 'b', name: 'Agargaon', toCampusMin: 20, fromCampusMin: 30),
    BusStop(id: 'c', name: 'Campus', toCampusMin: 50, fromCampusMin: 0),
  ],
  trips: [
    // Saturday–Thursday (Friday off).
    BusTrip(
      direction: BusDirection.toCampus,
      departsMin: 7 * 60 + 30,
      weekdays: {6, 7, 1, 2, 3, 4},
    ),
    BusTrip(
      direction: BusDirection.toCampus,
      departsMin: 9 * 60,
      weekdays: {6, 7, 1, 2, 3, 4},
    ),
    BusTrip(
      direction: BusDirection.fromCampus,
      departsMin: 17 * 60,
      weekdays: {6, 7, 1, 2, 3, 4},
    ),
  ],
);

void main() {
  // Wednesday 28 October 2026.
  test('next departures from a stop add the stop offset', () {
    final next = nextDepartures(
      _route,
      stopId: 'b',
      direction: BusDirection.toCampus,
      now: DateTime(2026, 10, 28, 7, 0),
    );
    expect(next.first.at, DateTime(2026, 10, 28, 7, 50));
    expect(next[1].at, DateTime(2026, 10, 28, 9, 20));
  });

  test('after the last bus: the next day it runs (Friday skipped)', () {
    final next = nextDepartures(
      _route,
      stopId: 'a',
      direction: BusDirection.toCampus,
      now: DateTime(2026, 10, 29, 10, 0), // Thursday, both buses gone
      limit: 1,
    );
    expect(next.single.at, DateTime(2026, 10, 31, 7, 30), reason: 'Saturday');
  });

  test('the way back uses the from-campus offsets', () {
    final next = nextDepartures(
      _route,
      stopId: 'a',
      direction: BusDirection.fromCampus,
      now: DateTime(2026, 10, 28, 12, 0),
      limit: 1,
    );
    expect(next.single.at, DateTime(2026, 10, 28, 17, 50));
  });

  test('a stop the bus skips that way has no departures', () {
    const route = BusRoute(
      id: 'r',
      name: 'x',
      stops: [BusStop(id: 's', name: 'S', toCampusMin: 0)],
      trips: [
        BusTrip(
          direction: BusDirection.fromCampus,
          departsMin: 600,
          weekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      ],
    );
    expect(
      nextDepartures(
        route,
        stopId: 's',
        direction: BusDirection.fromCampus,
        now: DateTime(2026, 10, 28),
      ),
      isEmpty,
    );
  });

  test('the route card shows the soonest departure', () {
    final next = nextRouteDeparture(_route, DateTime(2026, 10, 28, 12, 0))!;
    expect(next.trip.direction, BusDirection.fromCampus);
    expect(next.at, DateTime(2026, 10, 28, 17, 0));
    expect(_route.span, 'Mirpur 10 → Campus');
  });

  test('JSON round trip', () {
    final back = BusRoutes.fromJson(
      BusRoutes(routes: const [_route], canEdit: true).toJson(),
    );
    expect(back.canEdit, isTrue);
    expect(back.routes.single.stops[1].fromCampusMin, 30);
    expect(back.routes.single.trips.first.weekdays, {6, 7, 1, 2, 3, 4});
    expect(back.routes.single.trips.first.departsMin, 450);
  });
}
