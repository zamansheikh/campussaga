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
  late List<http.Request> seen;
  late Object? Function(http.Request) answer;
  late ApiClient api;
  late GrowthRepository repo;

  setUp(() {
    seen = [];
    answer = (_) => {};
    api = ApiClient(
      const ApiConfig(baseUrl: 'https://api.test/api/v1'),
      httpClient: MockClient((r) async {
        seen.add(r);
        final a = answer(r);
        return a == null ? http.Response('', 204) : ok(a);
      }),
    );
    repo = ApiGrowthRepository(api);
  });

  test('referrals and the claim', () async {
    answer = (r) => r.method == 'GET'
        ? {'code': 'abcd1234', 'link': 'l', 'invited': 3, 'joined': 1}
        : null;
    final s = await repo.referrals();
    expect(seen.single.url.path, '/api/v1/me/referrals');
    expect(s.invited, 3);

    await repo.claimReferral('abcd1234', source: 'join');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/api/v1/me/referral');
    expect(jsonDecode(seen.last.body), {'code': 'abcd1234', 'source': 'join'});
  });

  test('a refused claim is a typed failure the app can ignore', () async {
    final refused = ApiGrowthRepository(
      ApiClient(
        const ApiConfig(baseUrl: 'https://api.test/api/v1'),
        httpClient: MockClient(
          (r) async => http.Response(
            jsonEncode({
              'success': false,
              'data': null,
              'error': {'code': 'REFERRAL_TOO_LATE', 'message': 'late'},
            }),
            409,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
    );
    await expectLater(
      refused.claimReferral('abcd1234', source: 'link'),
      throwsA(
        isA<RejectedFailure>().having(
          (f) => f.code,
          'code',
          'REFERRAL_TOO_LATE',
        ),
      ),
    );
  });

  test('badges and the featured badge', () async {
    answer = (r) => r.url.path.endsWith('featured-badge')
        ? {
            'featured': {'key': 'cr', 'tier': 0},
          }
        : {'badges': [], 'all': [], 'featured': null};
    final b = await repo.myBadges();
    expect(seen.single.url.path, '/api/v1/me/badges');
    expect(b.featured, isNull);

    final f = await repo.setFeaturedBadge('cr');
    expect(seen.last.method, 'PUT');
    expect(seen.last.url.path, '/api/v1/me/featured-badge');
    expect(jsonDecode(seen.last.body), {'key': 'cr'});
    expect(f?.key, 'cr');

    answer = (_) => {'featured': null};
    expect(await repo.setFeaturedBadge(null), isNull);
    expect(jsonDecode(seen.last.body), {'key': null});
  });

  test('a student profile and the leaderboard hide switch', () async {
    answer = (_) => {'id': 'u9', 'name': 'Maliha'};
    final p = await repo.studentProfile('u9');
    expect(seen.single.url.path, '/api/v1/users/u9/profile');
    expect(p.name, 'Maliha');

    answer = (_) => {
      'id': 'u1',
      'email': 'a@diu.edu.bd',
      'role': 'student',
      'leaderboardHidden': true,
    };
    final u = await ApiProfileRepository(api)
        .setLeaderboardHidden(hidden: true);
    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/api/v1/me');
    expect(jsonDecode(seen.last.body), {'leaderboardHidden': true});
    expect(u.leaderboardHidden, isTrue);
  });

  test('campaigns, one campaign, the board and the claim', () async {
    answer = (r) {
      if (r.url.path.endsWith('/leaderboard')) {
        return {'rows': [], 'me': null};
      }
      if (r.url.path.endsWith('/claim')) return null;
      if (r.url.path.endsWith('/campaigns')) {
        return [
          {'id': 'c1', 'title': 'T', 'status': 'live'},
        ];
      }
      return {'id': 'c1', 'title': 'T', 'status': 'announced'};
    };
    final list = await repo.campaigns(lang: 'bn');
    expect(seen.last.url.path, '/api/v1/campaigns');
    expect(seen.last.url.queryParameters, {'lang': 'bn'});
    expect(list.single.id, 'c1');

    final c = await repo.campaign('c1');
    expect(seen.last.url.path, '/api/v1/campaigns/c1');
    expect(c.status, CampaignStatus.announced);

    await repo.leaderboard('c1', LeaderboardScope.university);
    expect(seen.last.url.path, '/api/v1/campaigns/c1/leaderboard');
    expect(seen.last.url.queryParameters, {'scope': 'university'});

    await repo.claimPrize(
      'c1',
      const PrizeClaim(fullName: 'Rafi', phone: '0171', address: 'Savar'),
    );
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/api/v1/campaigns/c1/claim');
    expect(jsonDecode(seen.last.body), {
      'fullName': 'Rafi',
      'phone': '0171',
      'address': 'Savar',
    });
  });
}
