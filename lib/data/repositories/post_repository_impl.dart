// lib/data/repositories/post_repository_impl.dart

import 'dart:io';
import 'package:campus_saga/data/datasources/remote/auth_remote_datasource.dart';
import 'package:campus_saga/data/datasources/remote/firebase_storage_remote_datasource.dart';
import 'package:campus_saga/data/datasources/remote/firestore_remote_datasource.dart';
import 'package:campus_saga/data/models/promotion_model.dart';
import 'package:campus_saga/data/models/university_model.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../core/errors/failures.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final FirebaseStorageRemoteDataSource firebaseStorageRemoteDataSource;
  final FirestoreRemoteDataSource firestoreRemoteDataSource;

  PostRepositoryImpl({
    required this.authRemoteDataSource,
    required this.firebaseStorageRemoteDataSource,
    required this.firestoreRemoteDataSource,
  });

  @override
  Future<Either<Failure, List<Post>>> getPostsByUniversity(
      String universityId) async {
    print("fetching posts for universityId: $universityId");
    try {
      final posts =
          await firestoreRemoteDataSource.getTimelinePosts(universityId);
      final postFromEntity = posts.map((post) => post.toEntity()).toList();
      return Right(postFromEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(Post post) async {
    try {
      await firestoreRemoteDataSource.createPost(PostModel.fromEntity(post));
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePostStatus(
      String postId, bool isResolved) async {
    try {
      await firestoreRemoteDataSource.updatePostStatus(postId, isResolved);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> fetchPosts(String universityId) async {
    try {
      final posts =
          await firestoreRemoteDataSource.getTimelinePosts(universityId);
      return Right(posts.map((post) => post.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadPostImages(
      String userId, List<File> image) async {
    try {
      final urls =
          await firebaseStorageRemoteDataSource.uploadPostImages(userId, image);
      return Right(urls);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment(Post post) async {
    try {
      final postModel = PostModel.fromEntity(post);
      await firestoreRemoteDataSource.updatePostComments(postModel);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFeedback(Post post) async {
    try {
      final postModel = PostModel.fromEntity(post);
      await firestoreRemoteDataSource.updatePostFeedback(postModel);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addVote(Post post) async {
    try {
      await firestoreRemoteDataSource.addVote(PostModel.fromEntity(post));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAgreeVote(Post post) async {
    try {
      await firestoreRemoteDataSource.addVote(PostModel.fromEntity(post));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addUniversity(University university) async {
    try {
      final result = await firestoreRemoteDataSource
          .addUniversity(UniversityModel.fromEntity(university));
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Promotion>> createPromotion(
      Promotion promotion) async {
    try {
      await firestoreRemoteDataSource
          .createPromotion(PromotionModel.fromEntity(promotion));
      return Right(promotion);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Promotion>>> getPromotionByUniversity(
      String universityId) async {
    try {
      final promotions = await firestoreRemoteDataSource
          .getPromotionByUniversity(universityId);
      final promotionFromEntity =
          promotions.map((promotion) => promotion.toEntity()).toList();
      return Right(promotionFromEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<University>>> fetchAllUniversity() async {
    try {
      final universities = await firestoreRemoteDataSource.getAllUniversity();
      final universityFromEntity =
          universities.map((university) => university.toEntity()).toList();
      return Right(universityFromEntity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateIssuePost(Post post) async {
    try {
      final postModel = PostModel.fromEntity(post);
      await firestoreRemoteDataSource.updateIssuePost(postModel);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIssue(Post post) async {
    try {
      final postModel = PostModel.fromEntity(post);
      await firestoreRemoteDataSource.deleteIssue(postModel);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePromotion(Promotion promotion) async {
    try {
      await firestoreRemoteDataSource
          .updatePromotion(PromotionModel.fromEntity(promotion));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
