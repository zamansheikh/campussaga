//write a use case that fetches posts from the repository via universityId
//fetch_posts.dart
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/repositories/post_repository.dart';
import 'package:dartz/dartz.dart';

class FetchPostsUsecase extends UseCase<List<Post>, String> {
  final PostRepository repository;

  FetchPostsUsecase(this.repository);

  @override
  Future<Either<Failure, List<Post>>> call(String universityId) async {
    return await repository.getPostsByUniversity(universityId);
  }
}
