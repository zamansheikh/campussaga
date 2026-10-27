part of 'email_sign_in_bloc.dart';

sealed class EmailSignInEvent extends Equatable {
  const EmailSignInEvent();

  @override
  List<Object?> get props => [];
}

/// "Send code" on the email step.
final class EmailSubmitted extends EmailSignInEvent {
  const EmailSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// The 6-digit code was entered (auto-submitted at 6 digits, or "Verify").
final class CodeSubmitted extends EmailSignInEvent {
  const CodeSubmitted(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// "Resend code".
final class ResendRequested extends EmailSignInEvent {
  const ResendRequested();
}

/// "Use a different email": back to the email step.
final class EmailChangeRequested extends EmailSignInEvent {
  const EmailChangeRequested();
}

/// One second of the resend countdown passed.
final class _ResendTicked extends EmailSignInEvent {
  const _ResendTicked(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object?> get props => [secondsLeft];
}
