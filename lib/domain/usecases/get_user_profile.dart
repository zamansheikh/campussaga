// lib/domain/usecases/get_user_profile.dart

import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetUserProfile extends UseCase<User, String> {
  final UserRepository repository;

  GetUserProfile(this.repository);

  @override
  Future<Either<Failure, User>> call(String userId) async {
    return await repository.getUserProfile(userId);
  }
}
