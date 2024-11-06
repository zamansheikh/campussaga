import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:equatable/equatable.dart';

class Post extends Equatable {
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
  final List<Comment> comments;
  final AuthorityFeedback? feedback;
  final Set<String> trueVoterIds; // Track users who voted true
  final Set<String> falseVoterIds; // Track users who voted false

  const Post({
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
    this.trueVoterIds = const {},
    this.falseVoterIds = const {},
  });

  bool hasUserVotedTrue(String userId) => trueVoterIds.contains(userId);
  bool hasUserVotedFalse(String userId) => falseVoterIds.contains(userId);

  Post toggleTrueVote(String voterId) {
    if (hasUserVotedTrue(voterId)) {
      return copyWith(
        trueVotes: trueVotes - 1,
        trueVoterIds: Set<String>.from(trueVoterIds)..remove(voterId),
      );
    } else {
      return copyWith(
        trueVotes: trueVotes + 1,
        falseVotes: hasUserVotedFalse(voterId) ? falseVotes - 1 : falseVotes,
        trueVoterIds: Set<String>.from(trueVoterIds)..add(voterId),
        falseVoterIds: Set<String>.from(falseVoterIds)..remove(voterId),
      );
    }
  }

  Post toggleFalseVote(String voterId) {
    if (hasUserVotedFalse(voterId)) {
      return copyWith(
        falseVotes: falseVotes - 1,
        falseVoterIds: Set<String>.from(falseVoterIds)..remove(voterId),
      );
    } else {
      return copyWith(
        falseVotes: falseVotes + 1,
        trueVotes: hasUserVotedTrue(voterId) ? trueVotes - 1 : trueVotes,
        falseVoterIds: Set<String>.from(falseVoterIds)..add(voterId),
        trueVoterIds: Set<String>.from(trueVoterIds)..remove(voterId),
      );
    }
  }

  Post copyWith({
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
    AuthorityFeedback? feedback,
    Set<String>? trueVoterIds,
    Set<String>? falseVoterIds,
  }) {
    return Post(
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
      trueVoterIds: trueVoterIds ?? this.trueVoterIds,
      falseVoterIds: falseVoterIds ?? this.falseVoterIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        universityId,
        postTitle,
        description,
        isResolved,
        timestamp,
        imageUrls,
        trueVotes,
        falseVotes,
        comments,
        feedback,
        trueVoterIds,
        falseVoterIds,
      ];
}
