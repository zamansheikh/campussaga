// lib/domain/repositories/post_repository.dart

import 'dart:io';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:dartz/dartz.dart';
import '../entities/post.dart';
import '../../core/errors/failures.dart';

abstract class PostRepository {
  Future<Either<Failure, List<Post>>> getPostsByUniversity(String universityId);
  Future<Either<Failure, List<Promotion>>> getPromotionByUniversity(String universityId);
  Future<Either<Failure, Post>> createPost(Post post);
  Future<Either<Failure, void>> updatePostStatus(String postId, bool isResolved);
  Future<Either<Failure, List<Post>>> fetchPosts(String universityId);
  Future<Either<Failure, List<String>>> uploadPostImages(String userId, List<File> image);
  //Add a comment to a specific post
  Future<Either<Failure, void>> addComment(Post post);
  Future<Either<Failure, void>> updateIssuePost(Post post);
  Future<Either<Failure, void>> updatePromotion(Promotion promotion);
  //Add feedback to a specific post
  Future<Either<Failure, void>> addFeedback(Post post);
  //Add a vote to a specific post
  Future<Either<Failure, void>> addVote(String postId, String userId, bool isTrueVote);
  //add university to university collection
  Future<Either<Failure, void>> addUniversity(University university);
  //Create a promotion post
  Future<Either<Failure, Promotion>> createPromotion(Promotion promotion);
  //Fetch all universities
  Future<Either<Failure, List<University>>> fetchAllUniversity();
}
