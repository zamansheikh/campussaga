import 'package:campus_saga/domain/entities/post.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class DeleteIssueUsecase  extends UseCase<void, Post> {
  final PostRepository repository;

  DeleteIssueUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(Post post) async {
    return await repository.deleteIssue(post);
  }
}