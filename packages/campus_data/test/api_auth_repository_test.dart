import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:campus_data/campus_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data, 'error': null, 'meta': {}}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response err(int status, String code) => http.Response(
  jsonEncode({
    'success': false,
    'data': null,
    'error': {'code': code, 'message': code},
    'meta': {},
  }),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> tokens(String n) => {
  'accessToken': 'access-$n',
  'accessTokenExpiresAt': '2099-01-01T00:00:00Z',
  'refreshToken': 'refresh-$n',
  'refreshTokenExpiresAt': '2099-01-01T00:00:00Z',
};

const user = {
  'id': 'u1',
  'email': 'a@demo.ac.bd',
  'role': 'student',
  'displayName': null,
  'department': null,
  'batch': null,
  'university': {
    'id': 'uni1',
    'slug': 'demo-university',
    'name': 'Demo University',
    'nameBn': null,
  },
};

void main() {
  test('Google sign-in stores the session and later calls use it', () async {
    final seen = <String>[];
    final store = MemoryTokenStore();
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://api.test/api/v1'),
      httpClient: MockClient((req) async {
        seen.add(
          '${req.method} ${req.url.path} ${req.headers['Authorization']}',
        );
        if (req.url.path.endsWith('/auth/google')) {
          expect(jsonDecode(req.body), {
            'idToken': 'fb-token',
            'name': 'Lina Akter',
          });
          return ok({'tokens': tokens('1'), 'user': user, 'isNewUser': true});
        }
        return ok(user);
      }),
    );
    final repo = ApiAuthRepository(api, store);

    final result = await repo.signInWithGoogle(
      'fb-token',
      name: ' Lina Akter ',
    );
    expect(result.isNewUser, isTrue);
    expect(result.user.university!.name, 'Demo University');
    expect(store.tokens?.refreshToken, 'refresh-1');

    expect(await repo.restoreSession(), isNotNull);
    expect(seen, [
      'POST /api/v1/auth/google null',
      'GET /api/v1/me Bearer access-1',
    ]);
  });

  test('an expired access token is refreshed once, then retried', () async {
    var refreshes = 0;
    final store = MemoryTokenStore();
    await store.write(AuthTokens.fromJson(tokens('old')));
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://api.test/api/v1'),
      httpClient: MockClient((req) async {
        if (req.url.path.endsWith('/auth/refresh')) {
          refreshes++;
          expect(jsonDecode(req.body), {'refreshToken': 'refresh-old'});
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return ok(tokens('new'));
        }
        if (req.headers['Authorization'] == 'Bearer access-old') {
          return err(401, 'TOKEN_EXPIRED');
        }
        return ok(user);
      }),
    );
    final repo = ApiAuthRepository(api, store);

    // Two calls at once: only ONE refresh may happen (a replayed refresh
    // token would end the session on the server).
    final results = await Future.wait([api.get('/me'), api.get('/me')]);
    expect(results, everyElement(isNotNull));
    expect(refreshes, 1);
    expect(store.tokens?.refreshToken, 'refresh-new');
    await repo.dispose();
  });

  test('a rejected refresh ends the session and forgets tokens', () async {
    final store = MemoryTokenStore();
    await store.write(AuthTokens.fromJson(tokens('old')));
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://api.test/api/v1'),
      httpClient: MockClient((req) async {
        if (req.url.path.endsWith('/auth/refresh')) {
          return err(401, 'REFRESH_INVALID');
        }
        return err(401, 'TOKEN_EXPIRED');
      }),
    );
    final repo = ApiAuthRepository(api, store);
    final ended = expectLater(repo.sessionEnded, emits(null));

    await expectLater(api.get('/me'), throwsA(isA<UnauthenticatedFailure>()));
    await ended;
    expect(store.tokens, isNull);
  });

  test('sign out clears tokens even when offline', () async {
    final store = MemoryTokenStore();
    await store.write(AuthTokens.fromJson(tokens('1')));
    final api = ApiClient(
      const ApiConfig(baseUrl: 'https://api.test/api/v1'),
      httpClient: MockClient(
        (_) async => throw http.ClientException('offline'),
      ),
    );
    await ApiAuthRepository(api, store).signOut();
    expect(store.tokens, isNull);
  });
}
