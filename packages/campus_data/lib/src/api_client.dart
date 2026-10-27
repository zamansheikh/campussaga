import 'dart:async';
import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:http/http.dart' as http;

/// Where the Campus Saga API lives, from the app's env file.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  /// e.g. https://api.example.com/api/v1 (Android emulator, local:
  /// http://10.0.2.2:8090/api/v1).
  final String baseUrl;
  final Duration timeout;

  bool get isConfigured => baseUrl.isNotEmpty;
}

/// Supplies the current access token, or null when signed out.
typedef AccessTokenProvider = FutureOr<String?> Function();

/// Thin JSON client for the Campus Saga API.
///
/// Every response uses the envelope
/// `{success, data, error: {code, message, details}, meta}`. Success returns
/// `data`; every failure is thrown as a typed [Failure] carrying the
/// backend's error code. Nothing else in the app talks HTTP.
class ApiClient {
  ApiClient(this.config, {http.Client? httpClient, this.accessToken})
    : _http = httpClient ?? http.Client();

  final ApiConfig config;
  final AccessTokenProvider? accessToken;
  final http.Client _http;

  Future<Object?> get(String path) => send('GET', path);

  Future<Object?> post(String path, [Object? body]) =>
      send('POST', path, body: body);

  Future<Object?> patch(String path, Object? body) =>
      send('PATCH', path, body: body);

  Future<Object?> delete(String path) => send('DELETE', path);

  Future<Object?> send(String method, String path, {Object? body}) async {
    final request = http.Request(method, Uri.parse('${config.baseUrl}$path'))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final token = await accessToken?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(config.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const NetworkFailure(message: 'Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: e.message);
    }

    if (response.statusCode == 204) return null;

    final Map<String, Object?> envelope;
    try {
      envelope =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
    } on Object {
      throw UnexpectedFailure(
        message: 'Invalid response (HTTP ${response.statusCode})',
      );
    }
    if (envelope['success'] == true) return envelope['data'];
    throw _failureFrom(response.statusCode, envelope['error']);
  }

  void close() => _http.close();
}

Failure _failureFrom(int status, Object? error) {
  final e = error is Map<String, Object?> ? error : const <String, Object?>{};
  final code = e['code'] as String? ?? 'HTTP_$status';
  final message = e['message'] as String?;
  final details = e['details'] is Map<String, Object?>
      ? e['details']! as Map<String, Object?>
      : null;

  switch (status) {
    case 401:
      return UnauthenticatedFailure(code: code, message: message);
    case 404:
      return NotFoundFailure(code: code, message: message);
    case 429:
      final secs = details?['retryAfterSeconds'];
      return RateLimitedFailure(
        code: code,
        message: message,
        retryAfter: secs is num ? Duration(seconds: secs.toInt()) : null,
      );
  }
  if (code == 'VALIDATION_FAILED') {
    final fields = details?['fields'];
    return ValidationFailure(
      fields is Map
          ? fields.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      code: code,
      message: message,
    );
  }
  if (status == 403 && code == 'FORBIDDEN') {
    return ForbiddenFailure(code: code, message: message);
  }
  if (status >= 500 && status != 502) {
    return UnexpectedFailure(code: code, message: message);
  }
  // Business rules: CODE_INVALID, CODE_EXPIRED, UNIVERSITY_EMAIL_REQUIRED,
  // EMAIL_SEND_FAILED, ...
  return RejectedFailure(code: code, message: message, details: details);
}
