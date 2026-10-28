import 'dart:convert';
import 'dart:typed_data';

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

http.Response fail(int status, String code) => http.Response(
  jsonEncode({
    'success': false,
    'data': null,
    'error': {'code': code, 'message': code},
    'meta': {},
  }),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const card = {
  'id': 'i1',
  'category': 'hostel',
  'private': false,
  'title': 'No water in Hall 2',
  'preview': 'Since Sunday…',
  'status': 'in_progress',
  'visibility': 'visible',
  'meTooCount': 12,
  'commentCount': 3,
  'imageCount': 1,
  'thumbnail': 'img1',
  'voted': true,
  'following': true,
  'mine': false,
  'author': null,
  'locationLabel': 'Hall 2',
  'createdAt': '2026-10-27T09:05:00Z',
  'statusChangedAt': '2026-10-28T09:00:00Z',
};

void main() {
  ApiClient client(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(
        const ApiConfig(baseUrl: 'https://api.test/api/v1'),
        httpClient: MockClient(handler),
        accessToken: () => 'tok',
      );

  test('feed, detail, vote and comments use the contract paths', () async {
    final seen = <String>[];
    final repo = ApiVoiceRepository(
      client((r) async {
        seen.add('${r.method} ${r.url.path}?${r.url.query} ${r.body}');
        return switch ((r.method, r.url.path)) {
          ('GET', '/api/v1/issues') => ok({
            'items': [card],
            'nextCursor': 'c2',
          }),
          ('GET', '/api/v1/issues/i1') => ok({
            ...card,
            'body': 'Details',
            'images': [
              {'id': 'img1', 'width': 1600, 'height': 1200},
            ],
            'timeline': [
              {
                'from': 'open',
                'to': 'in_progress',
                'actorKind': 'authority',
                'actorTitle': 'Hall Provost',
                'note': 'Pump ordered',
                'createdAt': '2026-10-28T09:00:00Z',
              },
            ],
            'can': {'changeStatus': true},
          }),
          ('PUT', '/api/v1/issues/i1/vote') => ok({
            'meTooCount': 13,
            'voted': true,
          }),
          ('POST', '/api/v1/issues/i1/comments') => ok({
            'id': 'c1',
            'kind': 'student',
            'handle': '7KQF',
            'isIssueAuthor': false,
            'mine': true,
            'body': 'Same here',
            'createdAt': '2026-10-28T10:00:00Z',
          }, 201),
          _ => ok(null),
        };
      }),
    );

    final page = await repo.feed(
      sort: IssueSort.newest,
      category: IssueCategory.hostel,
      query: ' water ',
    );
    expect(page.items.single.status, IssueStatus.inProgress);
    expect(page.nextCursor, 'c2');
    expect(seen.last, contains('sort=new&category=hostel&q=water'));

    final issue = await repo.issue('i1');
    expect(issue.timeline.single.actorTitle, 'Hall Provost');
    expect(issue.images.single.aspect, closeTo(1.333, 0.01));
    expect(issue.can.changeStatus, isTrue);

    final v = await repo.vote('i1', on: true);
    expect(v.meTooCount, 13);

    final c = await repo.addComment('i1', ' Same here ');
    expect(c.handle, '7KQF');
    expect(seen.last, contains('"body":"Same here","anonymous":true'));
  });

  test('uploads photos as multipart and loads images as bytes', () async {
    String? contentType;
    var calls = 0;
    final repo = ApiVoiceRepository(
      client((r) async {
        calls++;
        if (r.url.path == '/api/v1/uploads') {
          contentType = r.headers['content-type'];
          return ok({'id': 'up1', 'width': 1200, 'height': 900}, 201);
        }
        if (r.url.path == '/api/v1/issues/images/img1') {
          expect(r.headers['authorization'], 'Bearer tok');
          expect(r.url.query, 'size=thumb');
          return http.Response.bytes([1, 2, 3], 200);
        }
        return fail(404, 'ISSUE_NOT_FOUND');
      }),
    );
    final up = await repo.upload(Uint8List.fromList([9, 9, 9]));
    expect(up.id, 'up1');
    expect(contentType, startsWith('multipart/form-data'));
    expect(await repo.image('img1', thumb: true), [1, 2, 3]);
    await expectLater(
      repo.image('gone'),
      throwsA(
        isA<NotFoundFailure>().having((f) => f.code, 'code', 'ISSUE_NOT_FOUND'),
      ),
    );
    expect(calls, 3);
  });

  test('voice errors keep their codes', () async {
    final repo = ApiVoiceRepository(
      client((r) async => fail(403, 'FEATURE_DISABLED')),
    );
    await expectLater(
      repo.feed(),
      throwsA(
        isA<RejectedFailure>().having(
          (f) => f.code,
          'code',
          'FEATURE_DISABLED',
        ),
      ),
    );
  });
}
