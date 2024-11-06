// lib/data/repositories/post_repository_impl.dart

import 'dart:io';

import 'package:campus_saga/data/models/comment_model.dart';
import 'package:campus_saga/data/models/feedback_model.dart';
import 'package:campus_saga/data/models/university_model.dart';
import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/firebase_datasource.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final FirebaseDataSource dataSource;

  PostRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<Post>>> getPostsByUniversity(
      String universityId) async {
    print("fetching posts for universityId: $universityId");
    try {
      final posts = await dataSource.getTimelinePosts(universityId);
      final postFromEntity = posts.map((post) => post.toEntity()).toList();
      return Right(postFromEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(Post post) async {
    try {
      await dataSource.createPost(PostModel.fromEntity(post));
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePostStatus(
      String postId, bool isResolved) async {
    try {
      await dataSource.updatePostStatus(postId, isResolved);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> fetchPosts(String universityId) async {
    try {
      final posts = await dataSource.getTimelinePosts(universityId);
      return Right(posts.map((post) => post.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadPostImages(
      String userId, List<File> image) async {
    try {
      final urls = await dataSource.uploadPostImages(userId, image);
      return Right(urls);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment(
      String postId, Comment comment) async {
    try {
      await dataSource.addComment(postId, CommentModel.fromEntity(comment));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFeedback(
      String postId, AuthorityFeedback feedback) async {
    try {
      dataSource.addFeedback(
          postId, AuthorityFeedbackModel.fromEntity(feedback));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addVote(
      String postId, String userId, bool isTrueVote) async {
    try {
      await dataSource.addVote(postId, userId, isTrueVote);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addUniversity(University university)async {
    try {
      final result = await dataSource.addUniversity(UniversityModel.fromEntity(university));
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
