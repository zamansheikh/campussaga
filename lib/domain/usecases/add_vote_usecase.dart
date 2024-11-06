//add vote to a specific post
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class AddVoteUsecase extends UseCase<void, AddVoteParams> {
  final PostRepository repository;

  AddVoteUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddVoteParams params) async {
    return await repository.addVote(params.postId, params.userId, params.isTrueVote);
  }
}