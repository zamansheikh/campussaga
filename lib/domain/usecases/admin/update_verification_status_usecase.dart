import 'package:campussaga/core/errors/failures.dart';
import 'package:campussaga/core/usecases/usecase.dart';
import 'package:campussaga/domain/entities/varification_status.dart';
import 'package:campussaga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateVerificationStatusUsecase extends UseCase<void, Verification> {
  final UserRepository repository;
  UpdateVerificationStatusUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(Verification verification) {
    return repository.updateVerificationStatus(verification);
  }
}
