// lib/data/models/post_model.dart

import '../../domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required String id,
    required String description,
    required String userId,
    required String universityId,
    required DateTime timestamp,
  }) : super(
          id: id,
          description: description,
          userId: userId,
          universityId: universityId,
          timestamp: timestamp,
        );

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      description: json['description'] as String,
      userId: json['userId'] as String,
      universityId: json['universityId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'userId': userId,
      'universityId': universityId,
    };
  }

  static PostModel fromEntity(Post post) {
    return PostModel(
      id: post.id,
      description: post.description,
      userId: post.userId,
      universityId: post.universityId,
      timestamp: post.timestamp,
    );
  }
}
