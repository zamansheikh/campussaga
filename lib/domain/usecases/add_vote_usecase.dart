//add vote to a specific post
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class AddVote extends UseCase<void, AddVoteParams> {
  final PostRepository repository;

  AddVote(this.repository);

  @override
  Future<Either<Failure, void>> call(AddVoteParams params) async {
    return await repository.addVote(params.postId, params.userId, params.isTrueVote);
  }
}