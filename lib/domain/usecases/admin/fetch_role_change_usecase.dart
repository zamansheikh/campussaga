//fetch_posts.dart
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class FetchRoleChangeUsecase extends UseCase<List<RoleChange>, void> {
  final UserRepository repository;

  FetchRoleChangeUsecase(this.repository);

  @override
  Future<Either<Failure, List<RoleChange>>> call(void universityId) async {
    return await repository.loadAllRoleChangeRequest();
  }
}
