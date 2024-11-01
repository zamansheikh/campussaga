//sign in
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class SignInUser extends UseCase<String, UserParams> {
  final UserRepository repository;

  SignInUser(this.repository);

  @override
  Future<Either<Failure, String>> call(UserParams user) async {
    return await repository.signInUser(user);
  }
}