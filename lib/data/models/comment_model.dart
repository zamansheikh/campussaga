
import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required String id,
    required String userId,
    required String postId,
    required String text,
    required DateTime timestamp,
  }) : super(
          id: id,
          userId: userId,
          postId: postId,
          text: text,
          timestamp: timestamp,
        );

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CommentModel.fromEntity(Comment comment) {
    return CommentModel(
      id: comment.id,
      userId: comment.userId,
      postId: comment.postId,
      text: comment.text,
      timestamp: comment.timestamp,
    );
  }

  CommentModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? text,
    DateTime? timestamp,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}