// lib/data/repositories/user_repository_impl.dart

import 'dart:io';

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/data/models/user_model.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/firebase_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseDataSource dataSource;

  UserRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, User>> getUserProfile(String userId) async {
    try {
      final user = await dataSource.getUserProfile(userId);
      if (user != null) {
        return Right(user);
      } else {
        return Left(ServerFailure("User not found"));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createUserProfile(User user) async {
    try {
      await dataSource.createUser(user as UserModel);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(User user) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadUserImage(String userId, File image) {
    // TODO: implement uploadUserImage
    throw UnimplementedError();
  }
  
  @override
  Future<Either<Failure, String>> signUpUser(UserParams user) {
    // TODO: implement signUpUser
    throw UnimplementedError();
  }
}
