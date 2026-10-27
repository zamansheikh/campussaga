part of 'email_sign_in_bloc.dart';

enum EmailSignInStep { email, code }

enum EmailSignInStatus {
  idle,

  /// A request is in flight (button shows a spinner).
  submitting,

  /// Signed in; [EmailSignInState.result] is set.
  success,
}

final class EmailSignInState extends Equatable {
  const EmailSignInState({
    this.step = EmailSignInStep.email,
    this.status = EmailSignInStatus.idle,
    this.email = '',
    this.university,
    this.resendIn = 0,
    this.failure,
    this.result,
  });

  final EmailSignInStep step;
  final EmailSignInStatus status;

  /// The address the code was sent to (normalised by the server).
  final String email;

  /// The university the email belongs to, shown on the code step.
  final University? university;

  /// Seconds until "Resend code" is allowed (0 = now).
  final int resendIn;

  /// Why the last action failed; shown under the field.
  final Failure? failure;

  final SignInResult? result;

  bool get busy => status == EmailSignInStatus.submitting;

  EmailSignInState copyWith({
    EmailSignInStep? step,
    EmailSignInStatus? status,
    String? email,
    University? Function()? university,
    int? resendIn,
    Failure? Function()? failure,
    SignInResult? result,
  }) {
    return EmailSignInState(
      step: step ?? this.step,
      status: status ?? this.status,
      email: email ?? this.email,
      university: university != null ? university() : this.university,
      resendIn: resendIn ?? this.resendIn,
      failure: failure != null ? failure() : this.failure,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    step,
    status,
    email,
    university?.id,
    resendIn,
    failure?.runtimeType,
    failure?.code,
    result?.user.id,
  ];
}
