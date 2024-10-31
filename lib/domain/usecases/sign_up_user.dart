import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class SignUpUser extends UseCase<String, UserParams> {
  final UserRepository repository;

  SignUpUser(this.repository);

  @override
  Future<Either<Failure, String>> call(UserParams user) async {
    return await repository.signUpUser(user);
  }
}
