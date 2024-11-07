part of 'verify_user_bloc.dart';

sealed class VerifyUserState extends Equatable {
  const VerifyUserState();

  @override
  List<Object> get props => [];
}

class VerifyUserInitial extends VerifyUserState {}

class VerifyUserLoading extends VerifyUserState {}

class VerifyUserLoaded extends VerifyUserState {
  final List<Verification> verifications;
  const VerifyUserLoaded({required this.verifications});

  @override
  List<Object> get props => [verifications];
}

class VerifyUserError extends VerifyUserState {
  final String message;
  const VerifyUserError({required this.message});

  @override
  List<Object> get props => [message];
}