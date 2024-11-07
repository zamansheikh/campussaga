//fetch_posts.dart
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class FetchPendingVerificationUsecase extends UseCase<List<Verification>, String> {
  final UserRepository repository;

  FetchPendingVerificationUsecase(this.repository);

  @override
  Future<Either<Failure, List<Verification>>> call(String universityId) async {
    return await repository.getPendingVerificaionByUniversity(universityId);
  }
}
