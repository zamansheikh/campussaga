import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateUserRoleUsecase extends UseCase<void, UserRoleParams> {
  final UserRepository repository;
  UpdateUserRoleUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(UserRoleParams userRoleParams) {
    return repository.updateUserRole(userRoleParams);
  }
}