part of 'role_change_bloc.dart';

sealed class RoleChangeEvent extends Equatable {
  const RoleChangeEvent();

  @override
  List<Object> get props => [];
}


final class FetchRoleChangeEvent extends RoleChangeEvent {
  FetchRoleChangeEvent();
  @override
  List<Object> get props => [];
}

final class ChangeRoleEvent extends RoleChangeEvent {
  final RoleChange roleChange;

  ChangeRoleEvent(this.roleChange);

  @override
  List<Object> get props => [roleChange];
}

final class RoleChangeAccepted extends RoleChangeEvent {
  final RoleChange roleChange;
  RoleChangeAccepted(this.roleChange);
  @override
  List<Object> get props => [roleChange];
}