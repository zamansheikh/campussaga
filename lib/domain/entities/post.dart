// lib/domain/entities/post.dart

import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String id;
  final String userId;
  final String universityId;
  final String description;
  final bool isResolved;
  final DateTime timestamp;

  const Post({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.description,
    this.isResolved = false,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, userId, universityId, description, isResolved, timestamp];
}
