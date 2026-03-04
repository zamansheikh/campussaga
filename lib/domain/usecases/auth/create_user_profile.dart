// lib/domain/usecases/create_post.dart

import 'package:campussaga/domain/entities/user.dart';
import 'package:campussaga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';

class CreateUserProfile extends UseCase<void, User> {
  final UserRepository repository;

  CreateUserProfile(this.repository);

  @override
  Future<Either<Failure, void>> call(User user) async {
    return await repository.createUserProfile(user);
  }
}
