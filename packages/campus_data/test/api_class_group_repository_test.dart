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

const group = {
  'id': 'g1',
  'department': 'CSE',
  'batch': '61',
  'section': '',
  'semester': 'Fall 2026',
  'joinCode': 'KQWZRT',
  'role': 'member',
  'memberCount': 2,
  'slots': <Object?>[],
};

void main() {
  test('calls the class group endpoints', () async {
    final seen = <String>[];
    final client = MockClient((r) async {
      seen.add(
        '${r.method} ${r.url.path}${r.url.hasQuery ? '?${r.url.query}' : ''} ${r.body}',
      );
      return switch (r.url.path) {
        '/api/v1/groups' when r.method == 'GET' => ok({
          'groups': [group],
        }),
        '/api/v1/groups/preview' => ok({
          'department': 'CSE',
          'batch': '61',
          'semester': 'Fall 2026',
          'memberCount': 2,
          'classCount': 5,
          'isMember': false,
        }),
        '/api/v1/groups/join' => ok(group),
        '/api/v1/groups/g1/slots' => ok({
          'id': 's1',
          'courseCode': 'CSE311',
          'weekday': 1,
          'start': '09:00',
          'end': '10:30',
          'kind': 'theory',
        }, 201),
        _ => http.Response('', 204),
      };
    });
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://api.test/api/v1'),
      httpClient: client,
      accessToken: () => 't',
    );
    final repo = ApiClassGroupRepository(api);

    expect((await repo.myGroups()).single.title, 'CSE 61');
    expect((await repo.preview(' kqwzrt ')).classCount, 5);
    expect((await repo.join('kqwzrt')).id, 'g1');
    final s = await repo.addSlot(
      'g1',
      const SlotDraft(
        courseCode: 'CSE311',
        weekday: 1,
        startMin: 540,
        endMin: 630,
      ),
    );
    expect(s.endMin, 630);
    await repo.leave('g1');
    await repo.deleteSlot('g1', 'a/b');

    expect(seen, [
      'GET /api/v1/groups ',
      'GET /api/v1/groups/preview?code=KQWZRT ',
      'POST /api/v1/groups/join {"code":"KQWZRT"}',
      'POST /api/v1/groups/g1/slots {"courseCode":"CSE311","courseTitle":"","teacher":"","room":"","weekday":1,"start":"09:00","end":"10:30","kind":"theory"}',
      'POST /api/v1/groups/g1/leave ',
      'DELETE /api/v1/groups/g1/slots/a%2Fb ',
    ]);
  });

  test('tests and deadlines endpoints', () async {
    final seen = <String>[];
    const a = {
      'id': 'a1',
      'kind': 'class_test',
      'courseCode': 'CSE 101',
      'courseTitle': '',
      'date': '2026-10-30',
      'start': '10:00',
      'end': '10:30',
      'room': '402',
      'topics': 'Ch 1-3',
      'createdBy': {'id': 'u1', 'name': 'Rafi'},
      'canEdit': true,
    };
    final client = MockClient((r) async {
      seen.add('${r.method} ${r.url.path} ${r.body}');
      return r.method == 'DELETE'
          ? http.Response('', 204)
          : ok(a, r.method == 'POST' ? 201 : 200);
    });
    final repo = ApiClassGroupRepository(
      ApiClient(
        const ApiConfig(baseUrl: 'https://api.test/api/v1'),
        httpClient: client,
        accessToken: () => 't',
      ),
    );
    final draft = AssessmentDraft(
      kind: AssessmentKind.classTest,
      courseCode: 'CSE 101',
      date: DateTime(2026, 10, 30),
      startMin: 600,
      endMin: 630,
      room: '402',
      topics: 'Ch 1-3',
    );
    final added = await repo.addAssessment('g1', draft);
    expect(added.createdByName, 'Rafi');
    expect(added.canEdit, isTrue);
    await repo.updateAssessment('g1', 'a1', draft);
    await repo.deleteAssessment('g1', 'a1');
    const body =
        '{"kind":"class_test","courseCode":"CSE 101","courseTitle":"","date":"2026-10-30","start":"10:00","end":"10:30","room":"402","topics":"Ch 1-3"}';
    expect(seen, [
      'POST /api/v1/groups/g1/assessments $body',
      'PUT /api/v1/groups/g1/assessments/a1 $body',
      'DELETE /api/v1/groups/g1/assessments/a1 ',
    ]);
  });
}
