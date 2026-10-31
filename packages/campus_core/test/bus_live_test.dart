import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

const _days = {1, 2, 3, 4, 6, 7}; // Sat–Thu

const _route = BusRoute(
  id: 'r',
  name: 'Mirpur',
  stops: [
    BusStop(id: 'a', name: 'Mirpur 10', toCampusMin: 0, fromCampusMin: 40),
    BusStop(id: 'b', name: 'Agargaon', toCampusMin: 20, fromCampusMin: 20),
    BusStop(id: 'c', name: 'Campus', toCampusMin: 40, fromCampusMin: 0),
  ],
  trips: [
    BusTrip(
      direction: BusDirection.toCampus,
      departsMin: 7 * 60 + 30,
      weekdays: _days,
    ),
    BusTrip(
      direction: BusDirection.toCampus,
      departsMin: 8 * 60 + 30,
      weekdays: _days,
    ),
    BusTrip(
      direction: BusDirection.fromCampus,
      departsMin: 23 * 60 + 40,
      weekdays: _days,
    ),
  ],
);

void main() {
  group('BusLive.fromJson', () {
    test('reads runs, ETAs and my session', () {
      final live = BusLive.fromJson({
        'runs': [
          {
            'direction': 'to_campus',
            'departs': '07:30',
            'riders': 3,
            'position': {'lat': 23.8, 'lng': 90.36},
            'onRoute': true,
            'progress': 2500.0,
            'length': 10000,
            'speed': 6.1,
            'delayMin': 4,
            'nextStopId': 'b',
            'passed': ['a'],
            'etas': [
              {'stopId': 'b', 'at': '2026-10-27T02:00:00Z'},
            ],
            'updatedAt': '2026-10-27T01:55:00Z',
            'mine': true,
          },
          {
            'direction': 'from_campus',
            'departs': null,
            'riders': 1,
            'position': {'lat': 23.7, 'lng': 90.4},
            'updatedAt': '2026-10-27T01:55:00Z',
          },
        ],
        'mySession': {'id': 's1', 'direction': 'to_campus', 'departs': '07:30'},
      });
      final run = live.runs.first;
      expect(run.departsMin, 450);
      expect(run.riders, 3);
      expect(run.fraction, 0.25);
      expect(run.passed, {'a'});
      expect(run.etas['b'], DateTime.utc(2026, 10, 27, 2).toLocal());
      expect(run.key, 'to_campus|450');
      expect(run.mine, isTrue);
      expect(live.runs.last.departsMin, isNull);
      expect(live.runs.last.key, 'from_campus|-1');
      expect(live.runs.last.fraction, isNull);
      expect(live.mySession?.id, 's1');
    });

    test('nothing live', () {
      final live = BusLive.fromJson({'runs': [], 'mySession': null});
      expect(live.isEmpty, isTrue);
      expect(live.mySession, isNull);
    });
  });

  test('BusPoint leaves out unknown speed and heading', () {
    final p = BusPoint(
      at: DateTime.utc(2026, 10, 27, 2),
      lat: 23.8,
      lng: 90.4,
      accuracy: 8,
      speed: -1,
      heading: 90,
    );
    expect(p.toJson(), {
      'at': '2026-10-27T02:00:00.000Z',
      'lat': 23.8,
      'lng': 90.4,
      'accuracy': 8.0,
      'heading': 90.0,
    });
  });

  test('ping results and the end of a session', () {
    final r = BusPingResult.fromJson({
      'ended': true,
      'reason': 'off_route',
      'riders': 2,
    });
    expect(r.ended, isTrue);
    expect(r.reason, BusShareEnd.offRoute);
    expect(BusPingResult.fromJson({'ended': false}).reason, isNull);
    expect(BusShareEnd.parse('nonsense'), BusShareEnd.stopped);
  });

  group('trip notes', () {
    BusTripInsight insight({
      int votes = 0,
      int onTime = 0,
      int late = 0,
      int noShow = 0,
      int crowded = 0,
      int? delayMin,
      int runs = 0,
    }) => BusTripInsight(
      direction: BusDirection.toCampus,
      departsMin: 450,
      votes: votes,
      onTime: onTime,
      late: late,
      noShow: noShow,
      crowded: crowded,
      delayMin: delayMin,
      runs: runs,
    );

    test('say nothing on too little data', () {
      expect(insight(votes: 2, late: 2, crowded: 2).notes, isEmpty);
      expect(insight(delayMin: 12, runs: 2).notes, isEmpty);
    });

    test('measured delay wins over votes', () {
      expect(insight(votes: 5, onTime: 5, delayMin: 9, runs: 3).notes, [
        const BusTripNote(BusTripNoteKind.oftenLate, minutes: 9),
      ]);
      expect(insight(delayMin: 2, runs: 4).notes, [
        const BusTripNote(BusTripNoteKind.usuallyOnTime),
      ]);
    });

    test('votes: late, on time, crowded, no-show', () {
      expect(insight(votes: 4, late: 2, onTime: 2).notes, [
        const BusTripNote(BusTripNoteKind.oftenLate),
      ]);
      expect(
        insight(votes: 10, onTime: 7, late: 1, noShow: 2, crowded: 6).notes,
        [
          const BusTripNote(BusTripNoteKind.usuallyOnTime),
          const BusTripNote(BusTripNoteKind.sometimesNoShow),
          const BusTripNote(BusTripNoteKind.oftenCrowded),
        ],
      );
      // Mixed: no verdict on time.
      expect(insight(votes: 10, onTime: 5, late: 4, noShow: 1).notes, isEmpty);
    });
  });

  group('running trips', () {
    // Tuesday.
    DateTime at(int h, int m) => DateTime(2026, 10, 27, h, m);

    test('from 10 min before departure to 30 min after the last stop', () {
      expect(runningTrips(_route, at(7, 19)), isEmpty);
      expect(runningTrips(_route, at(7, 20)).single.trip.departsMin, 450);
      // 7:30 + 40 min + 30 min.
      expect(runningTrips(_route, at(8, 40)).first.trip.departsMin, 510);
      expect(
        runningTrips(_route, at(8, 40)).map((t) => t.trip.departsMin),
        [510, 450], // nearest departure first
      );
      expect(runningTrips(_route, at(8, 41)).single.trip.departsMin, 510);
    });

    test('a late trip runs past midnight', () {
      final t = runningTrips(_route, DateTime(2026, 10, 28, 0, 10)).single;
      expect(t.trip.direction, BusDirection.fromCampus);
      expect(t.day, DateTime(2026, 10, 27));
    });

    test('not on days off', () {
      expect(runningTrips(_route, DateTime(2026, 10, 30, 7, 30)), isEmpty);
    });

    test('sharing allows a wider window', () {
      expect(runningTrips(_route, at(7, 0)), isEmpty);
      expect(shareableTrips(_route, at(7, 0)).single.trip.departsMin, 450);
      expect(busTripSpan(_route, BusDirection.toCampus), 40);
    });
  });

  group('recent trip at my stop', () {
    test('the latest one past it within 3 hours', () {
      final r = recentTripAt(_route, 'b', DateTime(2026, 10, 27, 9, 0))!;
      expect(r.trip.trip.departsMin, 510);
      expect(r.at, DateTime(2026, 10, 27, 8, 50));
    });

    test('none yet, or too long ago', () {
      expect(recentTripAt(_route, 'b', DateTime(2026, 10, 27, 7, 49)), isNull);
      expect(recentTripAt(_route, 'b', DateTime(2026, 10, 27, 12)), isNull);
      expect(recentTripAt(_route, 'x', DateTime(2026, 10, 27, 9)), isNull);
    });
  });
}
