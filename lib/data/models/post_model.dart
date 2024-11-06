// post_model.dart
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/data/models/comment_model.dart';
import 'package:campus_saga/data/models/feedback_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String universityId;
  final String postTitle;
  final String description;
  final bool isResolved;
  final DateTime timestamp;
  final List<String> imageUrls;
  final int trueVotes;
  final int falseVotes;
  final List<CommentModel> comments;
  final AuthorityFeedbackModel? feedback;

  const PostModel({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.postTitle,
    required this.description,
    this.isResolved = false,
    required this.timestamp,
    this.imageUrls = const [],
    this.trueVotes = 0,
    this.falseVotes = 0,
    this.comments = const [],
    this.feedback,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        universityId: json['universityId'] as String,
        postTitle: json['postTitle'] as String,
        description: json['description'] as String,
        isResolved: json['isResolved'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        trueVotes: json['trueVotes'] as int? ?? 0,
        falseVotes: json['falseVotes'] as int? ?? 0,
        comments: (json['comments'] as List<dynamic>?)
                ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        feedback: json['feedback'] == null
            ? null
            : AuthorityFeedbackModel.fromJson(json['feedback'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
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
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'feedback': feedback?.toJson(),
      };

  factory PostModel.fromEntity(Post entity) => PostModel(
        id: entity.id,
        userId: entity.userId,
        universityId: entity.universityId,
        postTitle: entity.postTitle,
        description: entity.description,
        isResolved: entity.isResolved,
        timestamp: entity.timestamp,
        imageUrls: entity.imageUrls,
        trueVotes: entity.trueVotes,
        falseVotes: entity.falseVotes,
        comments: entity.comments.map((comment) => CommentModel.fromEntity(comment)).toList(),
        feedback: entity.feedback != null ? AuthorityFeedbackModel.fromEntity(entity.feedback!) : null,
      );

  Post toEntity() => Post(
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
        comments: comments.map((comment) => comment.toEntity()).toList(),
        feedback: feedback?.toEntity(),
      );

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
    List<CommentModel>? comments,
    AuthorityFeedbackModel? feedback,
  }) =>
      PostModel(
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