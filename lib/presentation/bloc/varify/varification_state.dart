part of 'varification_bloc.dart';

sealed class VarificationState extends Equatable {
  const VarificationState();
  
  @override
  List<Object> get props => [];
}

final class VarificationInitial extends VarificationState {}

final class VarificationInProgress extends VarificationState {}

final class VarificationSuccess extends VarificationState {
  final String successMessage;

  const VarificationSuccess(this.successMessage);

  @override
  List<Object> get props => [successMessage];
}

final class VarificationError extends VarificationState {
  final String errorMessage;

  const VarificationError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}