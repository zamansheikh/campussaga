import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class AddCommentUsecase  extends UseCase<void, AddCommentParams> {
  final PostRepository repository;

  AddCommentUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddCommentParams params) async {
    return await repository.addComment(params.postId, params.comment);
  }
}