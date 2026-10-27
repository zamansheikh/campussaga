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

const me = {
  'id': 'u1',
  'email': 'rafi@diu.edu.bd',
  'role': 'student',
  'displayName': 'Rafi',
  'department': 'CSE',
  'batch': '61',
  'university': {'id': 'uni1', 'slug': 'diu', 'name': 'DIU', 'nameBn': null},
};

void main() {
  test(
    'updateProfile sends all three fields and returns the profile',
    () async {
      late http.Request seen;
      final repo = ApiProfileRepository(
        ApiClient(
          const ApiConfig(baseUrl: 'https://api.test/api/v1'),
          httpClient: MockClient((r) async {
            seen = r;
            return ok(me);
          }),
        ),
      );
      final user = await repo.updateProfile(
        displayName: 'Rafi',
        department: 'CSE',
        batch: '61',
      );
      expect(seen.method, 'PATCH');
      expect(jsonDecode(seen.body), {
        'displayName': 'Rafi',
        'department': 'CSE',
        'batch': '61',
      });
      expect(user.isComplete, isTrue);
    },
  );

  test('suggestions encode the query', () async {
    late Uri seen;
    final repo = ApiProfileRepository(
      ApiClient(
        const ApiConfig(baseUrl: 'https://api.test/api/v1'),
        httpClient: MockClient((r) async {
          seen = r.url;
          return ok({
            'departments': ['CSE', 'Computer Science'],
          });
        }),
      ),
    );
    expect(await repo.departmentSuggestions(' c&s '), [
      'CSE',
      'Computer Science',
    ]);
    expect(seen.path, '/api/v1/me/department-suggestions');
    expect(seen.queryParameters['q'], 'c&s');
  });

  test(
    'deleteAccount forgets the session only after the server agreed',
    () async {
      final store = MemoryTokenStore();
      await store.write(
        AuthTokens(
          accessToken: 'a',
          accessTokenExpiresAt: DateTime(2099),
          refreshToken: 'r',
          refreshTokenExpiresAt: DateTime(2099),
        ),
      );
      var fail = true;
      final api = ApiClient(
        const ApiConfig(baseUrl: 'https://api.test/api/v1'),
        httpClient: MockClient((r) async {
          expect(r.method, 'DELETE');
          if (fail) throw http.ClientException('offline');
          return http.Response('', 204);
        }),
      );
      final repo = ApiAuthRepository(api, store);

      await expectLater(repo.deleteAccount(), throwsA(isA<NetworkFailure>()));
      expect(
        store.tokens,
        isNotNull,
        reason: 'still signed in if delete failed',
      );

      fail = false;
      await repo.deleteAccount();
      expect(store.tokens, isNull);
    },
  );
}
