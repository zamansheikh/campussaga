// lib/domain/repositories/user_repository.dart

import 'dart:io';

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUserProfile(String userId);
  Future<Either<Failure, void>> createUserProfile(User user);
  Future<Either<Failure, void>> updateUserProfile(User user);
  Future<Either<Failure, String>> uploadUserImage(String userId, File image);
  Future<Either<Failure, String>> signUpUser(UserParams user);
  Future<Either<Failure, String>> signInUser(UserParams user);
  Future<Either<Failure, void>> signOutUser();
  Future<Either<Failure, List<String>>> uploadVerificationImages(
      String userId, List<File> image);
  Future<Either<Failure, Verification>> varificationRequest(
      Verification verification);
  Future<Either<Failure, List<Verification>>> getPendingVerificaionByUniversity(
      String universityId);
  Future<Either<Failure, void>> updateVerificationStatus(
      Verification verification);
  Future<Either<Failure, void>> changeRoleRequest(RoleChange role_change);
  Future<Either<Failure, List<RoleChange>>> loadAllRoleChangeRequest();
  Future<Either<Failure, void>> updateUserRole(UserRoleParams userRoleParams);
}
