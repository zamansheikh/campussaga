import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/app/di.dart';
import 'package:varsitykotha/features/transport/data/bus_sharing.dart';
import 'package:varsitykotha/features/transport/data/my_location.dart';
import 'package:varsitykotha/features/transport/data/transport_store.dart';
import 'package:varsitykotha/features/transport/presentation/bus_cubit.dart';

import 'bus_routes_test.dart' show FakeTransportRepository, mirpur;
import 'helpers/fakes.dart';

/// Live buses over a fake server (docs/BUS_LIVE.md §3).
class FakeBusLiveRepository implements BusLiveRepository {
  BusLive now = BusLive.none;
  Map<String, int> routesLive = {};
  List<BusTripInsight> trips = [];
  final alertsSaved = <BusAlert>[];
  Failure? startFail;
  Failure? pingFail;
  BusPingResult nextPing = const BusPingResult(riders: 2);
  BusShareThanks thanks = const BusShareThanks(helped: 12, trips: 3);
  final pings = <List<BusPoint>>[];
  final started = <({BusDirection direction, int? departsMin})>[];
  final stopped = <String>[];
  final votes = <({BusTripStatus status, bool crowded, int departs})>[];

  @override
  Future<BusLive> live(String routeId) async => now;

  @override
  Future<Map<String, int>> liveRoutes() async => routesLive;

  @override
  Future<({String sessionId, BusLive live})> startSharing(
    String routeId, {
    required BusDirection direction,
    int? departsMin,
    required double lat,
    required double lng,
    double accuracy = 0,
  }) async {
    if (startFail case final f?) throw f;
    started.add((direction: direction, departsMin: departsMin));
    return (sessionId: 's${started.length}', live: now);
  }

  @override
  Future<BusPingResult> ping(String sessionId, List<BusPoint> points) async {
    if (pingFail case final f?) throw f;
    pings.add(points);
    return nextPing;
  }

  @override
  Future<BusShareThanks> stopSharing(String sessionId) async {
    stopped.add(sessionId);
    return thanks;
  }

  @override
  Future<BusTripInsight> sendFeedback(
    String routeId, {
    required BusDirection direction,
    required int departsMin,
    required DateTime date,
    required BusTripStatus status,
    bool crowded = false,
  }) async {
    votes.add((status: status, crowded: crowded, departs: departsMin));
    return BusTripInsight(
      direction: direction,
      departsMin: departsMin,
      votes: 1,
      onTime: status == BusTripStatus.onTime ? 1 : 0,
    );
  }

  @override
  Future<List<BusTripInsight>> insights(String routeId) async => trips;

  @override
  Future<List<BusAlert>> alerts() async => alertsSaved;

  @override
  Future<BusAlert> setAlert(
    String routeId, {
    required String stopId,
    required BusDirection direction,
    required int leadMin,
  }) async {
    final a = BusAlert(
      routeId: routeId,
      stopId: stopId,
      direction: direction,
      leadMin: leadMin,
    );
    alertsSaved
      ..removeWhere((x) => x.direction == direction)
      ..add(a);
    return a;
  }

  @override
  Future<void> removeAlert(String routeId, BusDirection direction) async =>
      alertsSaved.removeWhere((x) => x.direction == direction);
}

Position _pos(double lat, double lng, DateTime at) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: at,
  accuracy: 8,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 90,
  headingAccuracy: 0,
  speed: 6,
  speedAccuracy: 0,
);

class FakeMyLocation extends MyLocation {
  FakeMyLocation();

  Position? here = _pos(23.80, 90.36, DateTime(2026, 10, 27, 8, 25));
  LocationProblem problem = LocationProblem.denied;
  final moves = StreamController<Position>.broadcast();
  String? notice;

  @override
  Future<({Position? position, LocationProblem? problem})> current() async =>
      (position: here, problem: here == null ? problem : null);

  @override
  Stream<Position> sharing({
    required String title,
    required String text,
    required String channel,
  }) {
    notice = title;
    return moves.stream;
  }
}

const _notice = (title: 'Sharing', text: 'Open to stop', channel: 'Live');

void main() {
  late FakeBusLiveRepository repo;
  late FakeMyLocation location;

  setUp(() {
    repo = FakeBusLiveRepository();
    location = FakeMyLocation();
    MyLocation.instance = location;
    // Tuesday 8:25 AM: the 8:30 bus is about to leave.
    appNow = () => DateTime(2026, 10, 27, 8, 25);
  });
  tearDown(() {
    MyLocation.instance = const MyLocation();
    appNow = DateTime.now;
  });

  group('sharing a bus', () {
    late BusSharing sharing;
    setUp(
      () => sharing = BusSharing(repo, flushEvery: const Duration(hours: 1)),
    );
    tearDown(() => sharing.close());

    Future<BusShareProblem?> start() => sharing.start(
      mirpur,
      direction: BusDirection.toCampus,
      departsMin: 510,
      day: DateTime(2026, 10, 27, 8, 25),
      notice: _notice,
    );

    test('sends points in batches until the bus arrives', () async {
      expect(await start(), isNull);
      expect(repo.started.single, (
        direction: BusDirection.toCampus,
        departsMin: 510,
      ));
      expect(location.notice, 'Sharing');
      expect(sharing.state.sharing('mirpur'), isTrue);

      for (var i = 1; i <= 3; i++) {
        location.moves.add(
          _pos(23.80 - i / 1000, 90.36, DateTime(2026, 10, 27, 8, 25, i * 10)),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(sharing.state.queued, 4); // the first fix and three more
      await sharing.flush();
      expect(repo.pings.single, hasLength(4));
      expect(sharing.state.riders, 2);
      expect(sharing.state.queued, 0);

      // The server says it reached campus: sharing ends with thanks.
      repo.nextPing = const BusPingResult(
        ended: true,
        reason: BusShareEnd.arrived,
      );
      location.moves.add(_pos(23.7, 90.36, DateTime(2026, 10, 27, 9, 10)));
      await Future<void>.delayed(Duration.zero);
      await sharing.flush();
      expect(sharing.state.active, isFalse);
      final ended = sharing.state.ended!;
      expect(ended.reason, BusShareEnd.arrived);
      expect(ended.thanks?.helped, 12);
      expect(ended.departsMin, 510);
      expect(repo.stopped, ['s1']);

      // Later points go nowhere.
      location.moves.add(_pos(23.7, 90.36, DateTime(2026, 10, 27, 9, 11)));
      await Future<void>.delayed(Duration.zero);
      expect(sharing.state.queued, 0);
      sharing.seenEnded();
      expect(sharing.state.ended, isNull);
    });

    test('keeps points while offline and sends them later', () async {
      await start();
      repo.pingFail = const NetworkFailure();
      location.moves.add(_pos(23.79, 90.36, DateTime(2026, 10, 27, 8, 26)));
      await Future<void>.delayed(Duration.zero);
      await sharing.flush();
      expect(sharing.state.offline, isTrue);
      expect(sharing.state.queued, 2);

      repo.pingFail = null;
      await sharing.flush();
      expect(sharing.state.offline, isFalse);
      expect(repo.pings.single, hasLength(2));
    });

    test('stop sends what is left, then says thanks', () async {
      await start();
      await sharing.stop();
      expect(repo.pings.single, hasLength(1));
      expect(sharing.state.ended?.reason, BusShareEnd.stopped);
      expect(sharing.state.ended?.thanks?.trips, 3);
    });

    test('explains why it could not start', () async {
      repo.startFail = const RejectedFailure(code: 'NOT_ON_ROUTE');
      final refused = await start();
      expect(refused, isA<BusShareRefused>());
      expect(sharing.state.active, isFalse);

      location.here = null;
      final noFix = await start();
      expect(noFix, isA<BusShareNoLocation>());
      expect(sharing.state.active, isFalse);
    });
  });

  group('the route page', () {
    late MemoryTransportStore store;
    late BusSharing sharing;

    Future<void> open(
      WidgetTester tester, {
      String? myStop = 'aga',
      bool flag = true,
    }) async {
      usePhoneScreen(tester);
      final config = FakeAppConfigRepository()
        ..config = AppConfig(
          minSupportedBuild: 1,
          features: {'myClass': true, 'busLive': flag},
        );
      final (auth, _) = await registerFakes(config: config);
      auth.savedUser = testUser;
      final transport = FakeTransportRepository(routes: [mirpur]);
      store = MemoryTransportStore();
      if (myStop != null) store.stops['u1'] = {'mirpur': myStop};
      sharing = BusSharing(repo, flushEvery: const Duration(hours: 1));
      getIt
        ..registerSingleton<TransportRepository>(transport)
        ..registerSingleton<TransportStore>(store)
        ..registerSingleton<BusCubit>(BusCubit(transport, store))
        ..registerSingleton<BusLiveRepository>(repo)
        ..registerSingleton<BusSharing>(sharing);
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bus routes'));
      await tester.pumpAndSettle();
    }

    Future<void> openRoute(WidgetTester tester) async {
      await tester.tap(find.text('Mirpur'));
      await tester.pumpAndSettle();
    }

    testWidgets('a live bus: where it is and when it reaches my stop', (
      tester,
    ) async {
      appNow = () => DateTime(2026, 10, 27, 8, 40);
      repo
        ..routesLive = {'mirpur': 3}
        ..now = BusLive(
          runs: [
            BusRun(
              direction: BusDirection.toCampus,
              departsMin: 510,
              riders: 3,
              lat: 23.79,
              lng: 90.37,
              progress: 2000,
              length: 8000,
              delayMin: 1,
              nextStopId: 'aga',
              passed: const {'m10'},
              etas: {'aga': DateTime(2026, 10, 27, 8, 46)},
              updatedAt: DateTime(2026, 10, 27, 8, 39, 50),
            ),
          ],
        );
      await open(tester);

      // The list marks the route live.
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('3 students sharing'), findsOneWidget);

      await openRoute(tester);
      expect(find.text('On the way to Agargaon'), findsOneWidget);
      expect(find.text('3 students sharing · On time'), findsOneWidget);
      expect(find.text('At Agargaon in ~6 min'), findsOneWidget);
      expect(find.text('10 s ago'), findsOneWidget);
      // Nobody is asked to share a bus that is already live.
      expect(find.text('On the 8:30\u202fAM bus?'), findsNothing);
    });

    testWidgets('a rider shares the bus, then rates the trip', (tester) async {
      await open(tester);
      await openRoute(tester);

      expect(find.text('On the 8:30\u202fAM bus?'), findsOneWidget);
      await tester.tap(find.text("I'm on this bus"));
      await tester.pumpAndSettle();

      // What is shared and who sees it, then Start.
      expect(find.text('Share this bus live'), findsOneWidget);
      expect(
        find.text('Students on this route see the bus, never who shares it.'),
        findsOneWidget,
      );
      expect(find.text('To campus · 8:30\u202fAM'), findsOneWidget); // picked
      await tester.tap(find.text('Start sharing'));
      await tester.pumpAndSettle();
      expect(repo.started.single.departsMin, 510);
      expect(find.text("You're sharing this bus live"), findsOneWidget);
      expect(find.text('Only you so far'), findsOneWidget);

      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      expect(find.text('Thanks for sharing!'), findsOneWidget);
      expect(
        find.text('12 students watched your bus. 3 trips shared so far'),
        findsOneWidget,
      );
      expect(find.text('How was the 8:30\u202fAM bus?'), findsOneWidget);
      // The sheet is on top of the page.
      await tester.tap(find.text('It was crowded').last);
      await tester.pump();
      await tester.tap(find.text('On time').last);
      await tester.pumpAndSettle();
      expect(repo.votes.single, (
        status: BusTripStatus.onTime,
        crowded: true,
        departs: 510,
      ));
      expect(find.text('Thanks for sharing!'), findsNothing);
      expect(
        find.text('Thanks! This helps everyone on the route.'),
        findsOneWidget,
      );
    });

    testWidgets('asks once how the bus past my stop was', (tester) async {
      appNow = () => DateTime(2026, 10, 27, 9);
      await open(tester);
      await openRoute(tester);

      expect(find.text('How was the 8:30\u202fAM bus?'), findsOneWidget);
      expect(find.textContaining('Agargaon at 8:45\u202fAM'), findsOneWidget);
      await tester.tap(find.text('Late'));
      await tester.pumpAndSettle();
      expect(repo.votes.single.status, BusTripStatus.late);
      expect(find.text('How was the 8:30\u202fAM bus?'), findsNothing);
      expect(store.feedback['u1'], hasLength(2)); // the trip and the day
    });

    testWidgets('a "bus near" alert and what riders say about trips', (
      tester,
    ) async {
      repo.trips = [
        const BusTripInsight(
          direction: BusDirection.toCampus,
          departsMin: 510,
          votes: 5,
          onTime: 4,
          crowded: 4,
        ),
      ];
      await open(tester);
      await openRoute(tester);

      expect(
        find.text('Usually on time · Often crowded'),
        findsOneWidget, // under the next bus from my stop
      );
      await tester.tap(find.text('Alert me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min from my stop'));
      await tester.pumpAndSettle();
      expect(repo.alertsSaved.single.stopId, 'aga');
      expect(repo.alertsSaved.single.leadMin, 10);
      expect(find.text('Alert: 10 min'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('DEPARTURES'), 200);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Usually on time · Often crowded'),
        findsNWidgets(2),
      );
    });

    testWidgets('nothing live while the feature is off', (tester) async {
      repo.routesLive = {'mirpur': 3};
      await open(tester, flag: false);
      expect(find.text('LIVE'), findsNothing);
      await openRoute(tester);
      expect(find.text('On the 8:30\u202fAM bus?'), findsNothing);
      expect(find.text('Alert me'), findsNothing);
    });
  });
}
