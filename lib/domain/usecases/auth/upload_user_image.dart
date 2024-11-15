// lib/domain/usecases/upload_user_image.dart

import 'dart:io';
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';


class UploadUserImage {
  final UserRepository repository;

  UploadUserImage(this.repository);

  Future<Either<Failure, String>> call(String userId, File image) async {
    return await repository.uploadUserImage(userId, image);
  }
}
