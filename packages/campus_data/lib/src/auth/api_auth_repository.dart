import 'dart:async';

import 'package:campus_core/campus_core.dart';

import '../api_client.dart';
import 'token_store.dart';

/// [AuthRepository] on top of the VarsityKotha API.
///
/// It also owns the session for [ApiClient]: it hands out the access token
/// and refreshes it when the API says `TOKEN_EXPIRED`. Refreshes are
/// single-flight, because the server treats a replayed refresh token as
/// theft and ends the session.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._store) {
    _api.attachSession(accessToken: _accessToken, refresh: _refresh);
  }

  final ApiClient _api;
  final TokenStore _store;
  final _ended = StreamController<void>.broadcast();

  AuthTokens? _tokens;
  bool _loaded = false;
  Future<bool>? _refreshing;

  @override
  Stream<void> get sessionEnded => _ended.stream;

  Future<AuthTokens?> _current() async {
    if (!_loaded) {
      _tokens = await _store.read();
      _loaded = true;
    }
    return _tokens;
  }

  Future<String?> _accessToken() async => (await _current())?.accessToken;

  Future<void> _save(AuthTokens t) async {
    _tokens = t;
    _loaded = true;
    await _store.write(t);
  }

  Future<void> _forget() async {
    _tokens = null;
    _loaded = true;
    await _store.clear();
  }

  /// Returns true when a new access token is ready.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() {
    _refreshing = null;
  });

  Future<bool> _doRefresh() async {
    var current = await _current();
    if (current == null) return false;
    // Android can restart the app on some system changes; an earlier copy
    // may have refreshed and saved newer tokens since these were read.
    // Use those rather than send a replaced refresh token.
    final saved = await _store.read();
    if (saved != null && saved.refreshToken != current.refreshToken) {
      _tokens = current = saved;
      final fresh = saved.accessTokenExpiresAt.isAfter(
        DateTime.now().add(const Duration(seconds: 30)),
      );
      if (fresh) return true;
    }
    try {
      final data = await _api.post('/auth/refresh', {
        'refreshToken': current.refreshToken,
      }, false);
      await _save(AuthTokens.fromJson(data! as Map<String, Object?>));
      return true;
    } on UnauthenticatedFailure {
      await _forget();
      _ended.add(null);
      return false;
    }
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final tokens = await _current();
    if (tokens == null) return null;
    if (tokens.refreshTokenExpiresAt.isBefore(DateTime.now())) {
      await _forget();
      return null;
    }
    try {
      final data = await _api.get('/me');
      return UserProfile.fromJson(data! as Map<String, Object?>);
    } on UnauthenticatedFailure {
      await _forget();
      return null;
    }
  }

  @override
  Future<CodeSent> requestCode(String email) async {
    final data = await _api.post('/auth/code', {'email': email}, false);
    return CodeSent.fromJson(data! as Map<String, Object?>);
  }

  @override
  Future<SignInResult> verifyCode(String email, String code) =>
      _signIn('/auth/verify', {'email': email, 'code': code});

  @override
  Future<SignInResult> signInWithGoogle(
    String firebaseIdToken, {
    String? name,
  }) => _signIn('/auth/google', {
    'idToken': firebaseIdToken,
    if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
  });

  Future<SignInResult> _signIn(String path, Map<String, Object?> body) async {
    final data = (await _api.post(path, body, false))! as Map<String, Object?>;
    await _save(AuthTokens.fromJson(data['tokens']! as Map<String, Object?>));
    return SignInResult(
      user: UserProfile.fromJson(data['user']! as Map<String, Object?>),
      isNewUser: data['isNewUser'] == true,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      if (await _current() != null) await _api.post('/auth/logout');
    } on Failure {
      // Offline or already ended: forgetting locally is what matters.
    } finally {
      await _forget();
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _api.delete('/me'); // throws (and keeps the session) on failure
    await _forget();
  }

  Future<void> dispose() => _ended.close();
}
