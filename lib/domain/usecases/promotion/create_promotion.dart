import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:dartz/dartz.dart';
import '../../repositories/post_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';

class CreatePostUsecase extends UseCase<Promotion, Promotion> {
  final PostRepository repository;

  CreatePostUsecase(this.repository);

  @override
  Future<Either<Failure, Promotion>> call(Promotion promotion) async {
    return await repository.createPromotion(promotion);
  }
}