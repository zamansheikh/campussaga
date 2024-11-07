import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/domain/repositories/post_repository.dart';
import 'package:dartz/dartz.dart';

class FetchPromotionUsecase extends UseCase<List<Promotion>, String> {
  final PostRepository repository;

  FetchPromotionUsecase(this.repository);

  @override
  Future<Either<Failure, List<Promotion>>> call(String universityId) async {
    return await repository.getPromotionByUniversity(universityId);
  }
}
