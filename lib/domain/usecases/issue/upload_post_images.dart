// lib/domain/usecases/upload_user_image.dart

import 'dart:io';
import 'package:campus_saga/core/errors/failures.dart';
import 'package:campus_saga/domain/repositories/post_repository.dart';
import 'package:dartz/dartz.dart';


class UploadPostImages {
  final PostRepository repository;

  UploadPostImages(this.repository);

  Future<Either<Failure, List<String>>> call(String userId, List<File> image) async {
    return await repository.uploadPostImages(userId, image);
  }
}
