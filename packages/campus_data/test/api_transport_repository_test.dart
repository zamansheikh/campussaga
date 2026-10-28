import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:campus_data/campus_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response ok(Object? data, [int status = 200]) => http.Response(
  jsonEncode({'success': true, 'data': data, 'error': null, 'meta': {}}),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const route = {
  'id': 'r1',
  'name': 'Route 4',
  'color': '#0F766E',
  'notes': '',
  'active': true,
  'stops': [
    {
      'id': 's1',
      'name': 'Mirpur 10',
      'landmark': '',
      'toCampusMin': 0,
      'fromCampusMin': 50,
    },
  ],
  'trips': [
    {
      'id': 't1',
      'direction': 'to_campus',
      'departs': '07:30',
      'weekdays': [1, 6, 7],
      'note': '',
    },
  ],
};

void main() {
  test('calls the transport endpoints', () async {
    final seen = <String>[];
    final client = MockClient((r) async {
      seen.add('${r.method} ${r.url.path} ${r.body}');
      return switch (r.url.path) {
        '/api/v1/transport/routes' when r.method == 'GET' => ok({
          'routes': [route],
          'canEdit': true,
        }),
        '/api/v1/transport/routes/r1' when r.method == 'DELETE' =>
          http.Response('', 204),
        _ => ok(route, r.method == 'POST' ? 201 : 200),
      };
    });
    final repo = ApiTransportRepository(
      ApiClient(
        const ApiConfig(baseUrl: 'https://api.test/api/v1'),
        httpClient: client,
        accessToken: () => 't',
      ),
    );

    final all = await repo.routes();
    expect(all.canEdit, isTrue);
    expect(all.routes.single.trips.single.departsMin, 450);

    await repo.createRoute(name: 'Route 4', color: '#0F766E');
    await repo.setStops('r1', const [
      BusStop(id: '', name: 'Mirpur 10', toCampusMin: 0),
    ]);
    await repo.setTrips('r1', const [
      BusTrip(
        direction: BusDirection.fromCampus,
        departsMin: 17 * 60,
        weekdays: {7, 6},
      ),
    ]);
    await repo.deleteRoute('r1');

    expect(
      seen[1],
      startsWith('POST /api/v1/transport/routes {"name":"Route 4"'),
    );
    expect(seen[2], contains('"toCampusMin":0'));
    expect(
      seen[3],
      contains('"direction":"from_campus","departs":"17:00","weekdays":[6,7]'),
    );
    expect(seen[4], 'DELETE /api/v1/transport/routes/r1 ');
  });
}
