// lib/domain/usecases/upload_user_image.dart

import 'dart:io';
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';


class UploadVerificationImagesUsecase {
  final UserRepository repository;

  UploadVerificationImagesUsecase(this.repository);

  Future<Either<Failure, List<String>>> call(String userId, List<File> image) async {
    return await repository.uploadVerificationImages(userId, image);
  }
}
