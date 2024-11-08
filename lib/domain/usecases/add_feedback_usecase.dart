//add feedback to a specific post
import 'package:campus_saga/domain/entities/post.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class AddFeedbackUsecase  extends UseCase<void, Post> {
  final PostRepository repository;

  AddFeedbackUsecase(this.repository);

  Future<Either<Failure, void>> call(Post post) async {
    return await repository.addFeedback(post);
  }
}
