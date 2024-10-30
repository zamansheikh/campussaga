// lib/domain/repositories/post_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/post.dart';
import '../../core/errors/failures.dart';

abstract class PostRepository {
  Future<Either<Failure, List<Post>>> getPostsByUniversity(String universityId);
  Future<Either<Failure, Post>> createPost(Post post);
  Future<Either<Failure, void>> updatePostStatus(String postId, bool isResolved);
  Future<Either<Failure, List<Post>>> fetchPosts(String universityId);
}
