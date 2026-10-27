import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'email_sign_in_event.dart';
part 'email_sign_in_state.dart';

/// Counts down from [seconds] once per second (seconds-1, ..., 0).
typedef Ticker = Stream<int> Function(int seconds);

Stream<int> _realTicker(int seconds) => Stream<int>.periodic(
  const Duration(seconds: 1),
  (i) => seconds - i - 1,
).take(seconds);

/// Sign in with a university email and a 6-digit code:
/// email step → code step (with resend countdown) → signed in.
class EmailSignInBloc extends Bloc<EmailSignInEvent, EmailSignInState> {
  EmailSignInBloc({required AuthRepository repository, Ticker? ticker})
    : _repo = repository,
      _ticker = ticker ?? _realTicker,
      super(const EmailSignInState()) {
    on<EmailSubmitted>(_onEmail);
    on<CodeSubmitted>(_onCode);
    on<ResendRequested>(_onResend);
    on<EmailChangeRequested>(_onChangeEmail);
    on<_ResendTicked>(_onTick);
  }

  final AuthRepository _repo;
  final Ticker _ticker;
  StreamSubscription<int>? _countdown;

  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _codeShape = RegExp(r'^\d{6}$');

  Future<void> _onEmail(
    EmailSubmitted event,
    Emitter<EmailSignInState> emit,
  ) async {
    if (state.busy) return;
    final email = event.email.trim().toLowerCase();
    if (!_emailShape.hasMatch(email)) {
      emit(
        state.copyWith(
          email: email,
          failure: () => const ValidationFailure({
            'email': 'invalid',
          }, code: 'VALIDATION_FAILED'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: EmailSignInStatus.submitting,
        email: email,
        failure: () => null,
      ),
    );
    try {
      final sent = await _repo.requestCode(email);
      _startCountdown(sent.resendAfter.inSeconds);
      emit(
        state.copyWith(
          step: EmailSignInStep.code,
          status: EmailSignInStatus.idle,
          email: sent.email,
          university: () => sent.university,
          resendIn: sent.resendAfter.inSeconds,
        ),
      );
    } on RateLimitedFailure catch (f) {
      if (f.code != 'CODE_RESEND_TOO_SOON') {
        emit(state.copyWith(status: EmailSignInStatus.idle, failure: () => f));
        return;
      }
      // A code was sent to this address moments ago: just enter it.
      final wait = f.retryAfter?.inSeconds ?? 60;
      _startCountdown(wait);
      emit(
        state.copyWith(
          step: EmailSignInStep.code,
          status: EmailSignInStatus.idle,
          university: () => null,
          resendIn: wait,
        ),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: EmailSignInStatus.idle, failure: () => f));
    }
  }

  Future<void> _onCode(
    CodeSubmitted event,
    Emitter<EmailSignInState> emit,
  ) async {
    if (state.busy || state.status == EmailSignInStatus.success) return;
    final code = event.code.trim();
    if (!_codeShape.hasMatch(code)) return; // the field only submits 6 digits
    emit(
      state.copyWith(status: EmailSignInStatus.submitting, failure: () => null),
    );
    try {
      final result = await _repo.verifyCode(state.email, code);
      _stopCountdown();
      emit(state.copyWith(status: EmailSignInStatus.success, result: result));
    } on Failure catch (f) {
      emit(state.copyWith(status: EmailSignInStatus.idle, failure: () => f));
    }
  }

  Future<void> _onResend(
    ResendRequested event,
    Emitter<EmailSignInState> emit,
  ) async {
    if (state.busy || state.resendIn > 0) return;
    emit(
      state.copyWith(status: EmailSignInStatus.submitting, failure: () => null),
    );
    try {
      final sent = await _repo.requestCode(state.email);
      _startCountdown(sent.resendAfter.inSeconds);
      emit(
        state.copyWith(
          status: EmailSignInStatus.idle,
          university: () => sent.university,
          resendIn: sent.resendAfter.inSeconds,
        ),
      );
    } on RateLimitedFailure catch (f) {
      final wait = f.retryAfter?.inSeconds ?? 60;
      _startCountdown(wait);
      emit(
        state.copyWith(
          status: EmailSignInStatus.idle,
          resendIn: wait,
          failure: () => f,
        ),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: EmailSignInStatus.idle, failure: () => f));
    }
  }

  Future<void> _onChangeEmail(
    EmailChangeRequested event,
    Emitter<EmailSignInState> emit,
  ) async {
    _stopCountdown();
    emit(EmailSignInState(email: state.email));
  }

  void _onTick(_ResendTicked event, Emitter<EmailSignInState> emit) {
    emit(state.copyWith(resendIn: event.secondsLeft));
  }

  // Cancelling is fire-and-forget: nothing waits for the old countdown.
  void _stopCountdown() {
    unawaited(_countdown?.cancel());
    _countdown = null;
  }

  void _startCountdown(int seconds) {
    _stopCountdown();
    if (seconds <= 0) return;
    _countdown = _ticker(seconds).listen((s) => add(_ResendTicked(s)));
  }

  @override
  Future<void> close() {
    _stopCountdown();
    return super.close();
  }
}
