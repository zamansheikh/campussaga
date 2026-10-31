import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/google_auth.dart';
import '../../data/profile_cache.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Who is signed in. The router sends signed-out students to the sign-in
/// screen and signed-in students into the app.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required GoogleAuth google,
    ProfileCache? profileCache,
  }) : _repo = repository,
       _googleAuth = google,
       _cache = profileCache,
       super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthGoogleRequested>(_onGoogle);
    on<AuthSignedIn>(_onSignedIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthProfileUpdated>(
      (e, emit) => emit(state.copyWith(user: e.user, failure: () => null)),
    );
    on<AuthProfileSetupSkipped>(
      (e, emit) => emit(state.copyWith(profileSetupSkipped: true)),
    );
    on<AuthAccountDeleteRequested>(_onDelete);
    on<AuthRefreshRequested>(_onRefresh);
    on<_AuthSessionEnded>(_onSessionEnded);
    _ended = _repo.sessionEnded.listen((_) => add(const _AuthSessionEnded()));
  }

  final AuthRepository _repo;
  final GoogleAuth _googleAuth;
  final ProfileCache? _cache;
  late final StreamSubscription<void> _ended;

  /// Opened from the saved profile because the server couldn't be reached:
  /// checked again when the app comes back to the foreground.
  bool _offline = false;

  /// The profile on the phone follows who is signed in.
  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    final s = change.nextState;
    final user = s.user;
    if (s.status == AuthStatus.signedIn && user != null) {
      unawaited(_cache?.write(user));
    } else if (s.status == AuthStatus.signedOut) {
      unawaited(_cache?.clear());
    }
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.restoreSession();
      emit(
        user == null
            ? const AuthState(status: AuthStatus.signedOut)
            : AuthState(status: AuthStatus.signedIn, user: user),
      );
    } on Failure catch (f) {
      // No internet (or the server is down): the session is still valid
      // (an invalid one comes back as null above), so open with the saved
      // profile and routine instead of signing out.
      final saved = await _cache?.read();
      if (saved != null) {
        _offline = true;
        emit(AuthState(status: AuthStatus.signedIn, user: saved));
        return;
      }
      emit(AuthState(status: AuthStatus.signedOut, failure: f));
    } catch (e, s) {
      addError(e, s); // a bug: report it, but never hang on the splash
      emit(AuthState(status: AuthStatus.signedOut, failure: _unexpected(e)));
    }
  }

  Future<void> _onGoogle(
    AuthGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.signingIn) return; // ignore double taps
    emit(const AuthState(status: AuthStatus.signingIn));
    try {
      final google = await _googleAuth.signIn();
      if (google == null) {
        emit(const AuthState(status: AuthStatus.signedOut)); // cancelled
        return;
      }
      final result = await _repo.signInWithGoogle(
        google.idToken,
        name: google.name,
      );
      emit(
        AuthState(
          status: AuthStatus.signedIn,
          user: result.user,
          isNewUser: result.isNewUser,
        ),
      );
    } on Failure catch (f) {
      emit(AuthState(status: AuthStatus.signedOut, failure: f));
    } catch (e, s) {
      addError(e, s); // a bug: report it, but never leave the button spinning
      emit(AuthState(status: AuthStatus.signedOut, failure: _unexpected(e)));
    } finally {
      // Our backend session is what counts; forget the Google account so
      // the picker shows again (e.g. if a personal account was chosen).
      unawaited(_googleAuth.signOut());
    }
  }

  /// Back online after an offline start: fetch the real profile (or sign
  /// out if the session ended meanwhile).
  Future<void> _onRefresh(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!_offline || state.status != AuthStatus.signedIn) return;
    try {
      final user = await _repo.restoreSession();
      _offline = false;
      emit(
        user == null
            ? const AuthState(status: AuthStatus.signedOut)
            : state.copyWith(user: user, failure: () => null),
      );
    } on Failure {
      // Still offline: keep going with the saved profile.
    }
  }

  void _onSignedIn(AuthSignedIn event, Emitter<AuthState> emit) {
    emit(
      AuthState(
        status: AuthStatus.signedIn,
        user: event.result.user,
        isNewUser: event.result.isNewUser,
      ),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
    emit(const AuthState(status: AuthStatus.signedOut));
  }

  Future<void> _onDelete(
    AuthAccountDeleteRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.deleting || state.status != AuthStatus.signedIn) return;
    emit(state.copyWith(deleting: true, failure: () => null));
    try {
      await _repo.deleteAccount();
      unawaited(_googleAuth.signOut());
      emit(const AuthState(status: AuthStatus.signedOut));
    } on Failure catch (f) {
      // Still signed in: the account was not deleted.
      emit(state.copyWith(deleting: false, failure: () => f));
    } catch (e, s) {
      addError(e, s);
      emit(state.copyWith(deleting: false, failure: () => _unexpected(e)));
    }
  }

  void _onSessionEnded(_AuthSessionEnded event, Emitter<AuthState> emit) {
    if (state.status != AuthStatus.signedIn) return;
    emit(
      const AuthState(
        status: AuthStatus.signedOut,
        failure: UnauthenticatedFailure(code: 'SESSION_ENDED'),
      ),
    );
  }

  static Failure _unexpected(Object e) =>
      UnexpectedFailure(message: e.toString());

  @override
  Future<void> close() async {
    await _ended.cancel();
    return super.close();
  }
}
