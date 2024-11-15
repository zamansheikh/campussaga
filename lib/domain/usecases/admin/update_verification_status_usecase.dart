import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateVerificationStatusUsecase extends UseCase<void, Verification> {
  final UserRepository repository;
  UpdateVerificationStatusUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(Verification verification) {
    return repository.updateVerificationStatus(verification);
  }
}