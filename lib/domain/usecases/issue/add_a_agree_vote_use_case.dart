import 'package:campus_saga/domain/entities/post.dart';
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/post_repository.dart';

class AddAAgreeVoteUseCase extends UseCase<void, Post> {
  final PostRepository repository;

  AddAAgreeVoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Post post) async {
    return await repository.addAgreeVote(post);
  }
}
