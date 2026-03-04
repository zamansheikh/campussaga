import 'package:campussaga/domain/entities/post.dart';
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/post_repository.dart';

class AddVoteUsecase extends UseCase<void, Post> {
  final PostRepository repository;

  AddVoteUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(Post post) async {
    return await repository.addVote(post);
  }
}
