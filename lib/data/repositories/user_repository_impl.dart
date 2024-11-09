// lib/data/repositories/user_repository_impl.dart

import 'dart:io';

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/data/models/role_change_model.dart';
import 'package:campus_saga/data/models/user_model.dart';
import 'package:campus_saga/data/models/varification_status_model.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
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
      UserModel userModel = UserModel.fromEntity(user);
      await dataSource.createUser(userModel);
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
      final imageUrl = await dataSource.uploadUserImage(image, userId);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signUpUser(UserParams user) async {
    try {
      final right = await dataSource.signUpUser(user);
      return Right(right);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  //sign in
  @override
  Future<Either<Failure, String>> signInUser(UserParams user) async {
    try {
      final right = await dataSource.signInUser(user);
      return Right(right);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOutUser() async {
    try {
      return Right(dataSource.signOutUser());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadVerificationImages(
      String userId, List<File> image) async {
    try {
      final urls = await dataSource.uploadVerificationImages(userId, image);
      return Right(urls);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Verification>> varificationRequest(
      Verification verification) async {
    try {
      await dataSource.addVarificationRequest(
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
          await dataSource.getPendingVerificaionByUniversity(universityId);
      return Right(pendingList);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateVerificationStatus(
      Verification verification) async {
    try {
      dataSource.updateVerificationStatus(
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
      dataSource.changeRoleRequest(RoleChangeModel.fromEntity(role_change));
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoleChange>>> loadAllRoleChangeRequest() async {
    try {
      final roleChangeList = await dataSource.loadAllRoleChangeRequest();
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
      dataSource.updateUserRole(userRoleParams);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
