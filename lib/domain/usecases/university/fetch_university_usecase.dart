import 'package:campussaga/core/errors/failures.dart';
import 'package:campussaga/core/usecases/usecase.dart';
import 'package:campussaga/domain/entities/university.dart';
import 'package:campussaga/domain/repositories/post_repository.dart';
import 'package:dartz/dartz.dart';

class FetchUniversityUsecase extends UseCase<List<University>, void> {
  final PostRepository repository;

  FetchUniversityUsecase(this.repository);

  @override
  Future<Either<Failure, List<University>>> call(void params) async {
    return await repository.fetchAllUniversity();
  }
}
