import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/google_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Who is signed in. The router sends signed-out students to the sign-in
/// screen and signed-in students into the app.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository, required GoogleAuth google})
    : _repo = repository,
      _googleAuth = google,
      super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthGoogleRequested>(_onGoogle);
    on<AuthSignOutRequested>(_onSignOut);
    on<_AuthSessionEnded>(_onSessionEnded);
    _ended = _repo.sessionEnded.listen((_) => add(const _AuthSessionEnded()));
  }

  final AuthRepository _repo;
  final GoogleAuth _googleAuth;
  late final StreamSubscription<void> _ended;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.restoreSession();
      emit(
        user == null
            ? const AuthState(status: AuthStatus.signedOut)
            : AuthState(status: AuthStatus.signedIn, user: user),
      );
    } on Failure catch (f) {
      // TODO(R1): keep the student signed in offline with a cached profile.
      emit(AuthState(status: AuthStatus.signedOut, failure: f));
    }
  }

  Future<void> _onGoogle(
    AuthGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.signingIn) return; // ignore double taps
    emit(const AuthState(status: AuthStatus.signingIn));
    try {
      final idToken = await _googleAuth.signIn();
      if (idToken == null) {
        emit(const AuthState(status: AuthStatus.signedOut)); // cancelled
        return;
      }
      final result = await _repo.signInWithGoogle(idToken);
      emit(
        AuthState(
          status: AuthStatus.signedIn,
          user: result.user,
          isNewUser: result.isNewUser,
        ),
      );
    } on Failure catch (f) {
      emit(AuthState(status: AuthStatus.signedOut, failure: f));
    } finally {
      // Our backend session is what counts; forget the Google account so
      // the picker shows again (e.g. if a personal account was chosen).
      unawaited(_googleAuth.signOut());
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
    emit(const AuthState(status: AuthStatus.signedOut));
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

  @override
  Future<void> close() async {
    await _ended.cancel();
    return super.close();
  }
}
