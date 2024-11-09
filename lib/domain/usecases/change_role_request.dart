import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class ChangeRoleRequestUsecase  extends UseCase<void, RoleChange> {
  final UserRepository repository;

  ChangeRoleRequestUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(RoleChange role) async {
    return await repository.changeRoleRequest(role);
  }
}