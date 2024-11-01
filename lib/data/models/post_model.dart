import 'package:campus_saga/data/models/comment_model.dart';
import 'package:campus_saga/data/models/feedback_model.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/feedback.dart';

class PostModel extends Post {
  const PostModel({
    required String id,
    required String userId,
    required String universityId,
    required String postTitle,
    required String description,
    bool isResolved = false,
    required DateTime timestamp,
    List<String> imageUrls = const [],
    int trueVotes = 0,
    int falseVotes = 0,
    List<Comment> comments = const [],
    Feedback? feedback,
  }) : super(
          id: id,
          userId: userId,
          universityId: universityId,
          postTitle: postTitle,
          description: description,
          isResolved: isResolved,
          timestamp: timestamp,
          imageUrls: imageUrls,
          trueVotes: trueVotes,
          falseVotes: falseVotes,
          comments: comments,
          feedback: feedback,
        );

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      universityId: json['universityId'] as String,
      postTitle: json['postTitle'] as String,
      description: json['description'] as String,
      isResolved: json['isResolved'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrls: List<String>.from(json['imageUrls'] as List),
      trueVotes: json['trueVotes'] as int? ?? 0,
      falseVotes: json['falseVotes'] as int? ?? 0,
      comments: (json['comments'] as List)
          .map((comment) =>
              CommentModel.fromJson(comment as Map<String, dynamic>))
          .toList(),
      feedback: json['feedback'] != null
          ? FeedbackModel.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'universityId': universityId,
      'postTitle': postTitle,
      'description': description,
      'isResolved': isResolved,
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
      'trueVotes': trueVotes,
      'falseVotes': falseVotes,
      'comments': comments
          .map((comment) => CommentModel.fromEntity(comment).toJson())
          .toList(),
      'feedback': feedback != null
          ? FeedbackModel.fromEntity(feedback!).toJson()
          : null,
    };
  }

  factory PostModel.fromEntity(Post post) {
    return PostModel(
      id: post.id,
      userId: post.userId,
      universityId: post.universityId,
      postTitle: post.postTitle,
      description: post.description,
      isResolved: post.isResolved,
      timestamp: post.timestamp,
      imageUrls: post.imageUrls,
      trueVotes: post.trueVotes,
      falseVotes: post.falseVotes,
      comments: post.comments,
      feedback: post.feedback,
    );
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? universityId,
    String? postTitle,
    String? description,
    bool? isResolved,
    DateTime? timestamp,
    List<String>? imageUrls,
    int? trueVotes,
    int? falseVotes,
    List<Comment>? comments,
    Feedback? feedback,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      universityId: universityId ?? this.universityId,
      postTitle: postTitle ?? this.postTitle,
      description: description ?? this.description,
      isResolved: isResolved ?? this.isResolved,
      timestamp: timestamp ?? this.timestamp,
      imageUrls: imageUrls ?? this.imageUrls,
      trueVotes: trueVotes ?? this.trueVotes,
      falseVotes: falseVotes ?? this.falseVotes,
      comments: comments ?? this.comments,
      feedback: feedback ?? this.feedback,
    );
  }
}
