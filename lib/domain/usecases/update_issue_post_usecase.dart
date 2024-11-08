import 'package:campus_saga/domain/entities/post.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class UpdateIssuePostUsecase  extends UseCase<void, Post> {
  final PostRepository repository;

  UpdateIssuePostUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(Post post) async {
    return await repository.updateIssuePost(post);
  }
}