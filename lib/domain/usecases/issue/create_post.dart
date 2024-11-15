// lib/domain/usecases/create_post.dart

import 'package:dartz/dartz.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';

class CreatePost extends UseCase<Post, Post> {
  final PostRepository repository;

  CreatePost(this.repository);

  @override
  Future<Either<Failure, Post>> call(Post post) async {
    return await repository.createPost(post);
  }
}
