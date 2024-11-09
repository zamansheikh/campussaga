import 'package:bloc/bloc.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/usecases/change_role_request.dart';
import 'package:campus_saga/domain/usecases/fetch_role_change_usecase.dart';
import 'package:campus_saga/domain/usecases/update_user_role_usecase.dart';
import 'package:equatable/equatable.dart';

part 'role_change_event.dart';
part 'role_change_state.dart';

class RoleChangeBloc extends Bloc<RoleChangeEvent, RoleChangeState> {
  final FetchRoleChangeUsecase fetchRoleChangeUsecase;
  final ChangeRoleRequestUsecase changeRoleRequest;
  final UpdateUserRoleUsecase updateUserRoleUsecase;
  RoleChangeBloc({
    required this.fetchRoleChangeUsecase,
    required this.changeRoleRequest,
    required this.updateUserRoleUsecase,
  }) : super(RoleChangeInitial()) {
    on<FetchRoleChangeEvent>((event, emit) async {
      emit(RoleChangeLoading());
      final result = await fetchRoleChangeUsecase.call(null);
      result.fold(
        (failure) => emit(RoleChangeFailure(failure.toString())),
        (roleChangeList) => emit(RoleChangeSuccess(roleChangeList)),
      );
    });
    on<ChangeRoleEvent>((event, emit) async {
      emit(RoleChangeLoading());
      final result = await changeRoleRequest.call(event.roleChange);
      result.fold(
        (failure) => emit(RoleChangeFailure(failure.toString())),
        (_) {
          print("Role Changed applied to admin");
        },
      );
    });

    on<RoleChangeAccepted>((event, emit) async {
      final RoleChangedOrNot = await updateUserRoleUsecase.call(UserRoleParams(
          uuid: event.roleChange.uuid, role: event.roleChange.role));
      RoleChangedOrNot.fold(
        (failure) => emit(RoleChangeFailure(failure.toString())),
        (_) async {
          print("Role Changed by admin");
          final result = await changeRoleRequest.call(event.roleChange);
          result.fold(
            (failure) => emit(RoleChangeFailure(failure.toString())),
            (_) {
              print("Role Changed by admin and Updated in database");
            },
          );
        },
      );
    });
  }
}
