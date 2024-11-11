// lib/data/repositories/user_repository_impl.dart

import 'dart:io';

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/data/datasources/remote/auth_remote_datasource.dart';
import 'package:campus_saga/data/datasources/remote/firebase_storage_remote_datasource.dart';
import 'package:campus_saga/data/datasources/remote/firestore_remote_datasource.dart';
import 'package:campus_saga/data/models/role_change_model.dart';
import 'package:campus_saga/data/models/user_model.dart';
import 'package:campus_saga/data/models/varification_status_model.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/errors/failures.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final FirestoreRemoteDataSource firestoreRemoteDataSource;
  final FirebaseStorageRemoteDataSource firebaseStorageRemoteDataSource;

  UserRepositoryImpl({
    required this.authRemoteDataSource,
    required this.firestoreRemoteDataSource,
    required this.firebaseStorageRemoteDataSource,
  });

  @override
  Future<Either<Failure, User>> getUserProfile(String userId) async {
    try {
      final user = await firestoreRemoteDataSource.getUserProfile(userId);
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
      UserModel userModel = UserModel.fromEntity(user);
      await firestoreRemoteDataSource.createUser(userModel);
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
  Future<Either<Failure, String>> uploadUserImage(
      String userId, File image) async {
    try {
      final imageUrl = await firebaseStorageRemoteDataSource.uploadUserImage(image, userId);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signUpUser(UserParams user) async {
    try {
      final right = await authRemoteDataSource.signUpUser(user);
      return Right(right);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  //sign in
  @override
  Future<Either<Failure, String>> signInUser(UserParams user) async {
    try {
      final right = await authRemoteDataSource.signInUser(user);
      return Right(right);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOutUser() async {
    try {
      return Right(authRemoteDataSource.signOutUser());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadVerificationImages(
      String userId, List<File> image) async {
    try {
      final urls = await firebaseStorageRemoteDataSource.uploadVerificationImages(userId, image);
      return Right(urls);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Verification>> varificationRequest(
      Verification verification) async {
    try {
      await firestoreRemoteDataSource.addVarificationRequest(
          VerificationStatusModel.fromEntity(verification));
      return Right(verification);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Verification>>> getPendingVerificaionByUniversity(
      String universityId) async {
    try {
      final pendingList =
          await firestoreRemoteDataSource.getPendingVerificaionByUniversity(universityId);
      return Right(pendingList);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateVerificationStatus(
      Verification verification) async {
    try {
      firestoreRemoteDataSource.updateVerificationStatus(
          VerificationStatusModel.fromEntity(verification));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changeRoleRequest(
      RoleChange role_change) async {
    try {
      firestoreRemoteDataSource.changeRoleRequest(RoleChangeModel.fromEntity(role_change));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoleChange>>> loadAllRoleChangeRequest() async {
    try {
      final roleChangeList = await firestoreRemoteDataSource.loadAllRoleChangeRequest();
      final roleChangeEnityList =
          roleChangeList.map((e) => e.toEntity()).toList();
      return Right(roleChangeEnityList);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(
      UserRoleParams userRoleParams) async {
    try {
      firestoreRemoteDataSource.updateUserRole(userRoleParams);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
