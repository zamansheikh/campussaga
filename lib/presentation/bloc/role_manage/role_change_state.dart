part of 'role_change_bloc.dart';

sealed class RoleChangeState extends Equatable {
  const RoleChangeState();
  
  @override
  List<Object> get props => [];
}

final class RoleChangeInitial extends RoleChangeState {}

final class RoleChangeLoading extends RoleChangeState {}

final class RoleChangeSuccess extends RoleChangeState {
  final List<RoleChange> roleChangeList;

  RoleChangeSuccess(this.roleChangeList);

  @override
  List<Object> get props => [roleChangeList];
}

final class RoleChangeFailure extends RoleChangeState {
  final String message;

  RoleChangeFailure(this.message);

  @override
  List<Object> get props => [message];
}
