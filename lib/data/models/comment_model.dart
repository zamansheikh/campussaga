// comment_model.dart
import 'package:campus_saga/domain/entities/comment.dart';

class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String text;
  final DateTime timestamp;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.text,
    required this.timestamp,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        postId: json['postId'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'postId': postId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CommentModel.fromEntity(Comment entity) => CommentModel(
        id: entity.id,
        userId: entity.userId,
        postId: entity.postId,
        text: entity.text,
        timestamp: entity.timestamp,
      );

  Comment toEntity() => Comment(
        id: id,
        userId: userId,
        postId: postId,
        text: text,
        timestamp: timestamp,
      );

  CommentModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? text,
    DateTime? timestamp,
  }) =>
      CommentModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        postId: postId ?? this.postId,
        text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
      );
}