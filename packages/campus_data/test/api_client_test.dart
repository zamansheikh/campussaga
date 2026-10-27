import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:campus_data/campus_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response envelope(
  int status, {
  Object? data,
  Map<String, Object?>? error,
}) {
  return http.Response(
    jsonEncode({
      'success': error == null,
      'data': data,
      'error': error,
      'meta': {'timestamp': '2026-10-27T00:00:00.000Z'},
    }),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

ApiClient clientFor(
  Future<http.Response> Function(http.Request) handler, {
  String? token,
}) {
  return ApiClient(
    const ApiConfig(baseUrl: 'https://api.test/api/v1'),
    httpClient: MockClient(handler),
    accessToken: () => token,
  );
}

void main() {
  test('returns data and sends JSON + bearer token', () async {
    late http.Request seen;
    final api = clientFor((req) async {
      seen = req;
      return envelope(200, data: {'ok': true, 'name': 'ক্যাম্পাস'});
    }, token: 'abc');

    final data = await api.post('/auth/code', {'email': 'a@demo.ac.bd'});

    expect(data, {'ok': true, 'name': 'ক্যাম্পাস'});
    expect(seen.url.toString(), 'https://api.test/api/v1/auth/code');
    expect(seen.headers['Authorization'], 'Bearer abc');
    expect(jsonDecode(seen.body), {'email': 'a@demo.ac.bd'});
  });

  test('204 returns null', () async {
    final api = clientFor((_) async => http.Response('', 204));
    expect(await api.delete('/me'), isNull);
  });

  test(
    'maps error envelopes to typed failures with the backend code',
    () async {
      Future<Failure> failureFor(int status, Map<String, Object?> error) async {
        final api = clientFor((_) async => envelope(status, error: error));
        try {
          await api.get('/x');
        } on Failure catch (f) {
          return f;
        }
        fail('expected a failure');
      }

      final rate = await failureFor(429, {
        'code': 'CODE_RESEND_TOO_SOON',
        'message': 'wait',
        'details': {'retryAfterSeconds': 42},
      });
      expect(rate, isA<RateLimitedFailure>());
      expect(rate.code, 'CODE_RESEND_TOO_SOON');
      expect(
        (rate as RateLimitedFailure).retryAfter,
        const Duration(seconds: 42),
      );

      final invalid = await failureFor(400, {
        'code': 'VALIDATION_FAILED',
        'details': {
          'fields': {'email': 'must be a valid email address'},
        },
      });
      expect((invalid as ValidationFailure).fieldErrors, {
        'email': 'must be a valid email address',
      });

      final expired = await failureFor(401, {'code': 'TOKEN_EXPIRED'});
      expect(expired, isA<UnauthenticatedFailure>());
      expect(expired.code, 'TOKEN_EXPIRED');

      final rejected = await failureFor(400, {
        'code': 'CODE_INVALID',
        'details': {'remainingAttempts': 3},
      });
      expect(rejected, isA<RejectedFailure>());
      expect((rejected as RejectedFailure).details, {'remainingAttempts': 3});

      final notUni = await failureFor(403, {
        'code': 'UNIVERSITY_EMAIL_REQUIRED',
      });
      expect(notUni, isA<RejectedFailure>());
      expect(notUni.code, 'UNIVERSITY_EMAIL_REQUIRED');

      final server = await failureFor(500, {'code': 'INTERNAL_ERROR'});
      expect(server, isA<UnexpectedFailure>());
    },
  );

  test('network problems become NetworkFailure', () async {
    final api = clientFor((_) async => throw http.ClientException('offline'));
    expect(api.get('/me'), throwsA(isA<NetworkFailure>()));
  });

  test('a non-JSON response is unexpected, not a crash', () async {
    final api = clientFor((_) async => http.Response('<html>502</html>', 502));
    expect(api.get('/me'), throwsA(isA<UnexpectedFailure>()));
  });

  test(
    'a missing or invalid API address is a clear failure, not a crash',
    () async {
      for (final base in ['', '/api/v1', 'localhost:8090', 'ftp://x/api']) {
        expect(ApiConfig(baseUrl: base).isConfigured, isFalse, reason: base);
        final api = ApiClient(
          ApiConfig(baseUrl: base),
          httpClient: MockClient((_) async => fail('must not send')),
        );
        await expectLater(
          api.post('/auth/google', {'idToken': 'x'}),
          throwsA(
            isA<UnexpectedFailure>().having(
              (f) => f.code,
              'code',
              'API_NOT_CONFIGURED',
            ),
          ),
        );
      }
      expect(
        const ApiConfig(baseUrl: 'http://localhost:8090/api/v1').isConfigured,
        isTrue,
      );
    },
  );
}
