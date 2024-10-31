// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {} // For use cases that don't require parameters

class UserParams {
  final String email;
  final String password;
  UserParams ({required this.email, required this.password});
}