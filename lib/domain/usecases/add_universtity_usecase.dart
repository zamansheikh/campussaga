import 'package:campus_saga/domain/entities/university.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class AddUniverstityUsecase extends UseCase<void, University> {
  final PostRepository repository;

  AddUniverstityUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(University university) async {
    return await repository.addUniversity(university);
  }
}