import 'dart:convert';

import 'package:campus_core/campus_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the session tokens are kept between app starts.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// Keychain (iOS) / Android Keystore-backed storage.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'campus.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      // Corrupt or unreadable (e.g. restored from another device): start fresh.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) =>
      _storage.write(key: _key, value: jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// In-memory store (tests).
class MemoryTokenStore implements TokenStore {
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens t) async => tokens = t;

  @override
  Future<void> clear() async => tokens = null;
}
