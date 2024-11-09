import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class UpdatePromotionUsecase  extends UseCase<void, Promotion> {
  final PostRepository repository;

  UpdatePromotionUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(Promotion promotion) async {
    return await repository.updatePromotion(promotion);
  }
}