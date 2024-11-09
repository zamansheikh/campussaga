// lib/core/usecases/usecase.dart

import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {} // For use cases that don't require parameters

class UserParams {
  final String email;
  final String password;
  UserParams ({required this.email, required this.password});
}


class AddVoteParams {
  final String postId;
  final String userId;
  final bool isTrueVote;
  AddVoteParams({required this.postId, required this.userId, required this.isTrueVote});
}

class AddFeedbackParams {
  final String postId;
  final AuthorityFeedback feedback;
  AddFeedbackParams({required this.postId, required this.feedback});
}


class AddCommentParams {
  final String postId;
  final Comment comment;
  AddCommentParams({required this.postId, required this.comment});
}

class UserRoleParams {
  final String uuid;
  final String role;
  UserRoleParams({required this.uuid, required this.role});
}