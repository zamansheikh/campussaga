// lib/domain/repositories/user_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUserProfile(String userId);
  Future<Either<Failure, void>> createUserProfile(User user);
  Future<Either<Failure, void>> updateUserProfile(User user);
}
