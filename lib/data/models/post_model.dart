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
  final int agree;
  final int disagree;
  final List<CommentModel> comments;
  final AuthorityFeedbackModel? feedback;
  final Set<String> trueVoterIds;
  final Set<String> falseVoterIds;
  final Set<String> agreeVoterIds;
  final Set<String> disagreeVoterIds;

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
    this.agree = 0,
    this.disagree = 0,
    this.comments = const [],
    this.feedback,
    this.trueVoterIds = const {},
    this.falseVoterIds = const {},
    this.agreeVoterIds = const {},
    this.disagreeVoterIds = const {},
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        universityId: json['universityId'] as String,
        postTitle: json['postTitle'] as String,
        description: json['description'] as String,
        isResolved: json['isResolved'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        trueVotes: json['trueVotes'] as int? ?? 0,
        falseVotes: json['falseVotes'] as int? ?? 0,
        agree: json['agree'] as int? ?? 0,
        disagree: json['disagree'] as int? ?? 0,
        comments: (json['comments'] as List<dynamic>?)
                ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        feedback: json['feedback'] == null
            ? null
            : AuthorityFeedbackModel.fromJson(
                json['feedback'] as Map<String, dynamic>),
        trueVoterIds: Set<String>.from(json['trueVoterIds'] ?? []),
        falseVoterIds: Set<String>.from(json['falseVoterIds'] ?? []),
        agreeVoterIds: Set<String>.from(json['agreeVoterIds'] ?? []),
        disagreeVoterIds: Set<String>.from(json['disagreeVoterIds'] ?? []),
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
        'agree': agree,
        'disagree': disagree,
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'feedback': feedback?.toJson(),
        'trueVoterIds': trueVoterIds.toList(),
        'falseVoterIds': falseVoterIds.toList(),
        'agreeVoterIds': agreeVoterIds.toList(),
        'disagreeVoterIds': disagreeVoterIds.toList(),
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
        agree: entity.agree,
        disagree: entity.disagree,
        comments: entity.comments
            .map((comment) => CommentModel.fromEntity(comment))
            .toList(),
        feedback: entity.feedback != null
            ? AuthorityFeedbackModel.fromEntity(entity.feedback!)
            : null,
        trueVoterIds: entity.trueVoterIds,
        falseVoterIds: entity.falseVoterIds,
        agreeVoterIds: entity.agreeVoterIds,
        disagreeVoterIds: entity.disagreeVoterIds,
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
        agree: agree,
        disagree: disagree,
        comments: comments.map((comment) => comment.toEntity()).toList(),
        feedback: feedback?.toEntity(),
        trueVoterIds: trueVoterIds,
        falseVoterIds: falseVoterIds,
        agreeVoterIds: agreeVoterIds,
        disagreeVoterIds: disagreeVoterIds,
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
    int? agree,
    int? disagree,
    List<CommentModel>? comments,
    AuthorityFeedbackModel? feedback,
    Set<String>? trueVoterIds,
    Set<String>? falseVoterIds,
    Set<String>? agreeVoterIds,
    Set<String>? disagreeVoterIds,
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
        agree: agree ?? this.agree,
        disagree: disagree ?? this.disagree,
        comments: comments ?? this.comments,
        feedback: feedback ?? this.feedback,
        trueVoterIds: trueVoterIds ?? this.trueVoterIds,
        falseVoterIds: falseVoterIds ?? this.falseVoterIds,
        agreeVoterIds: agreeVoterIds ?? this.agreeVoterIds,
        disagreeVoterIds: disagreeVoterIds ?? this.disagreeVoterIds,
      );
}
