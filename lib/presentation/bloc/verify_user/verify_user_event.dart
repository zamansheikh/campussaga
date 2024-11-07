part of 'verify_user_bloc.dart';

sealed class VerifyUserEvent extends Equatable {
  const VerifyUserEvent();

  @override
  List<Object> get props => [];
}

class PendingVerificationLoadedEvent extends VerifyUserEvent {
  final String universtiyId;
  PendingVerificationLoadedEvent({
    required this.universtiyId,
  });

  @override
  List<Object> get props => [universtiyId];
}

class VerifyUserAcceptedEvent extends VerifyUserEvent {
  final Verification verification;
  VerifyUserAcceptedEvent({
    required this.verification,
  });

  @override
  List<Object> get props => [verification];
}

class VerifyUserRejectedEvent extends VerifyUserEvent {
  final Verification verification;
  VerifyUserRejectedEvent({
    required this.verification,
  });

  @override
  List<Object> get props => [verification];
}