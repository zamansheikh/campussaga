import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';

class CreateVarificationRequestUsecase extends UseCase<Verification, Verification> {
  final UserRepository repository;

  CreateVarificationRequestUsecase(this.repository);

  @override
  Future<Either<Failure, Verification>> call(Verification promotion) async {
    return await repository.varificationRequest(promotion);
  }
}