//add feedback to a specific post
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class AddFeedbackUsecase {
  final PostRepository repository;

  AddFeedbackUsecase(this.repository);

  Future<Either<Failure, void>> call(AddFeedbackParams params) async {
    return await repository.addFeedback(params.postId, params.feedback);
  }
}