part of 'admin_bloc.dart';

sealed class AdminState extends Equatable {
  const AdminState();
  
  @override
  List<Object> get props => [];
}

final class AdminInitial extends AdminState {}

final class AdminLoading extends AdminState {}

final class AdminSuccess extends AdminState {
  final String successMessage;

  const AdminSuccess(this.successMessage);

  @override
  List<Object> get props => [successMessage];
}

final class AdminError extends AdminState {
  final String errorMessage;

  const AdminError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}