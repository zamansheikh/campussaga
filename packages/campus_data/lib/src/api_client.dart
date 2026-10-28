import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Where the VarsityKotha API lives, from the app's env file.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  /// e.g. https://api.example.com/api/v1 (Android emulator, local:
  /// http://10.0.2.2:8090/api/v1).
  final String baseUrl;
  final Duration timeout;

  /// True when [baseUrl] is an absolute http(s) URL with a host.
  bool get isConfigured {
    final uri = Uri.tryParse(baseUrl);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

/// Supplies the current access token, or null when signed out.
typedef AccessTokenProvider = FutureOr<String?> Function();

/// Gets a new access token; true when one is ready.
typedef SessionRefresher = Future<bool> Function();

/// Thin JSON client for the VarsityKotha API.
///
/// Every response uses the envelope
/// `{success, data, error: {code, message, details}, meta}`. Success returns
/// `data`; every failure is thrown as a typed [Failure] carrying the
/// backend's error code. When a signed-in call answers `TOKEN_EXPIRED`, the
/// client refreshes the session once and retries. Nothing else in the app
/// talks HTTP.
class ApiClient {
  ApiClient(this.config, {http.Client? httpClient, this.accessToken})
    : _http = httpClient ?? http.Client();

  final ApiConfig config;
  final http.Client _http;
  AccessTokenProvider? accessToken;
  SessionRefresher? _refresh;

  /// Connects the session owner (the auth repository).
  void attachSession({
    required AccessTokenProvider accessToken,
    required SessionRefresher refresh,
  }) {
    this.accessToken = accessToken;
    _refresh = refresh;
  }

  Future<Object?> get(String path) => send('GET', path);

  Future<Object?> post(
    String path, [
    Object? body,
    bool authenticated = true,
  ]) => send('POST', path, body: body, authenticated: authenticated);

  Future<Object?> patch(String path, Object? body) =>
      send('PATCH', path, body: body);

  Future<Object?> put(String path, Object? body) =>
      send('PUT', path, body: body);

  Future<Object?> delete(String path) => send('DELETE', path);

  /// Raw bytes (images). Errors still come back as typed failures.
  Future<Uint8List> getBytes(String path) => _withRefresh(() async {
    final request = http.Request('GET', _uri(path));
    await _authorize(request);
    final response = await _execute(request);
    if (response.statusCode == 200) return response.bodyBytes;
    throw _decodeFailure(response);
  });

  /// Uploads one file as multipart/form-data under [field].
  Future<Object?> postMultipart(
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String method = 'POST',
  }) => _withRefresh(() async {
    final request = http.MultipartRequest(method, _uri(path))
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: _mediaType(contentType),
        ),
      );
    await _authorize(request);
    return _envelope(await _execute(request));
  });

  /// [authenticated] false sends no token (sign-in endpoints).
  Future<Object?> send(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    try {
      return await _send(method, path, body, authenticated);
    } on UnauthenticatedFailure catch (f) {
      final refresh = _refresh;
      if (!authenticated || f.code != 'TOKEN_EXPIRED' || refresh == null) {
        rethrow;
      }
      if (!await refresh()) rethrow;
      return _send(method, path, body, authenticated);
    }
  }

  Future<Object?> _send(
    String method,
    String path,
    Object? body,
    bool authenticated,
  ) async {
    final request = http.Request(method, _uri(path))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (authenticated) await _authorize(request);
    return _envelope(await _execute(request));
  }

  /// Retries once with a fresh token after `TOKEN_EXPIRED`.
  Future<T> _withRefresh<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on UnauthenticatedFailure catch (f) {
      final refresh = _refresh;
      if (f.code != 'TOKEN_EXPIRED' || refresh == null) rethrow;
      if (!await refresh()) rethrow;
      return call();
    }
  }

  Uri _uri(String path) {
    if (!config.isConfigured) {
      throw UnexpectedFailure(
        code: 'API_NOT_CONFIGURED',
        message: 'API base URL is not set or invalid: "${config.baseUrl}"',
      );
    }
    return Uri.parse('${config.baseUrl}$path');
  }

  Future<void> _authorize(http.BaseRequest request) async {
    final token = await accessToken?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<http.Response> _execute(http.BaseRequest request) async {
    try {
      final streamed = await _http.send(request).timeout(config.timeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const NetworkFailure(message: 'Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: e.message);
    } on Exception catch (e) {
      // Socket, TLS and other transport errors not wrapped by package:http.
      throw NetworkFailure(message: e.toString());
    }
  }

  Object? _envelope(http.Response response) {
    if (response.statusCode == 204) return null;
    final envelope = _decode(response);
    if (envelope['success'] == true) return envelope['data'];
    throw _failureFrom(response.statusCode, envelope['error']);
  }

  Failure _decodeFailure(http.Response response) =>
      _failureFrom(response.statusCode, _decode(response)['error']);

  Map<String, Object?> _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, Object?>;
    } on Object {
      throw UnexpectedFailure(
        message: 'Invalid response (HTTP ${response.statusCode})',
      );
    }
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
  if (status >= 500 && status != 502 && status != 503) {
    return UnexpectedFailure(code: code, message: message);
  }
  // Business rules: CODE_INVALID, CODE_EXPIRED, UNIVERSITY_EMAIL_REQUIRED,
  // EMAIL_SEND_FAILED, GOOGLE_SIGN_IN_UNAVAILABLE, ...
  return RejectedFailure(code: code, message: message, details: details);
}

/// "image/jpeg" → its MediaType (http_parser comes with package:http).
MediaType _mediaType(String contentType) {
  final parts = contentType.split('/');
  return MediaType(parts.first, parts.length > 1 ? parts[1] : 'octet-stream');
}
