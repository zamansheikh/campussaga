//sign_out_user.dart
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';

class SignOutUser implements UseCase<void, NoParams> {
  final UserRepository repository;

  SignOutUser(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOutUser();
  }
}