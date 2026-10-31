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

void main() {
  test('verification and feedback call the spec paths', () async {
    final seen = <String>[];
    final client = MockClient((r) async {
      seen.add(
        '${r.method} ${r.url.path}${r.url.hasQuery ? '?${r.url.query}' : ''} ${r.body}',
      );
      return switch (r.url.path) {
        '/api/v1/me/verification' => ok({'verified': false, 'needed': 2}),
        '/api/v1/vouch/abc' => ok({
          'student': {'id': 's', 'name': 'T'},
          'university': {'id': 'u', 'name': 'U'},
        }),
        '/api/v1/groups/g1/members/u2/confirm' => ok({
          'userId': 'u2',
          'name': 'Mim',
          'role': 'member',
          'verified': true,
        }),
        '/api/v1/universities/domain-requests' => ok({}, 202),
        '/api/v1/feedback' => ok({
          'id': 'f1',
          'kind': 'bug',
          'message': 'x',
          'status': 'new',
        }, 201),
        '/api/v1/me/feedback' => ok({'items': <Object?>[]}),
        _ => http.Response('{}', 404),
      };
    });
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://x.test/api/v1'),
      httpClient: client,
    );
    final v = ApiVerificationRepository(api);
    expect((await v.mine()).needed, 2);
    await v.vouchCard('abc');
    await v.vouch('abc');
    expect((await v.confirmMember('g1', 'u2')).verified, isTrue);
    await v.requestUniversity(email: 'a@b.c', universityName: ' New Uni ');

    final f = ApiFeedbackRepository(api);
    await f.send(const FeedbackDraft(kind: FeedbackKind.bug, message: 'x'));
    expect(await f.mine(), isEmpty);

    expect(seen, [
      'GET /api/v1/me/verification ',
      'GET /api/v1/vouch/abc ',
      'POST /api/v1/vouch/abc ',
      'POST /api/v1/groups/g1/members/u2/confirm ',
      'POST /api/v1/universities/domain-requests {"email":"a@b.c","universityName":"New Uni"}',
      startsWith('POST /api/v1/feedback {"kind":"bug"'),
      'GET /api/v1/me/feedback ',
    ]);
  });

  test('campus admin paths, paging and errors', () async {
    final seen = <String>[];
    final client = MockClient((r) async {
      seen.add(
        '${r.method} ${r.url.path}${r.url.hasQuery ? '?${r.url.query}' : ''} ${r.body}',
      );
      final p = r.url.path;
      if (p == '/api/v1/campus-admin/students' && r.method == 'GET') {
        return ok({
          'items': [
            {'id': 's1', 'name': 'Mim', 'verified': false},
          ],
          'page': 1,
          'pageSize': 1,
          'total': 3,
        });
      }
      if (p.endsWith('/unverify')) {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'EMAIL_VERIFIED', 'message': 'no'},
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      }
      if (p == '/api/v1/campus-admin/bus-reps') {
        return ok({
          'items': [
            {'userId': 'r1', 'name': 'Imran', 'email': 'hidden@x.y'},
          ],
        });
      }
      if (p == '/api/v1/campus-admin/sections') {
        return ok([
          {'id': 'a', 'name': 'A', 'members': 3, 'cr': <Object?>[]},
        ]);
      }
      return ok({});
    });
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://x.test/api/v1'),
      httpClient: client,
    );
    final repo = ApiCampusAdminRepository(api);

    final page = await repo.students(status: StudentStatus.all, query: ' mim ');
    expect(page.items.single.name, 'Mim');
    expect(page.nextPage, 2);
    await expectLater(
      repo.unverify('s1', 'why'),
      throwsA(
        isA<RejectedFailure>().having((f) => f.code, 'code', 'EMAIL_VERIFIED'),
      ),
    );
    expect((await repo.busReps()).single.name, 'Imran');
    expect((await repo.sections()).single.hasCr, isFalse);
    await repo.makeCr('a', 'u');
    await repo.removeCr('a', 'u');
    await repo.report(ReportKind.comment, 'c1', ReportAction.hide);
    await repo.closeBlood('b1', reason: 'done');
    await repo.escalate(EscalationKind.section, ' note ', targetId: 'a');

    expect(
      seen,
      containsAllInOrder([
        'GET /api/v1/campus-admin/students?status=all&q=mim ',
        'POST /api/v1/campus-admin/students/s1/unverify {"reason":"why"}',
        'PUT /api/v1/campus-admin/sections/a/cr {"userId":"u"}',
        'DELETE /api/v1/campus-admin/sections/a/cr/u ',
        'POST /api/v1/campus-admin/reports/comment/c1 {"action":"hide"}',
        'POST /api/v1/campus-admin/blood/b1/close {"reason":"done"}',
        'POST /api/v1/campus-admin/escalations {"kind":"section","targetId":"a","note":"note"}',
      ]),
    );
  });
}
