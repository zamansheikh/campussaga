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
  final int agree;
  final int disagree;
  final List<Comment> comments;
  final AuthorityFeedback? feedback;
  final Set<String> trueVoterIds; // Track users who voted true
  final Set<String> falseVoterIds; // Track users who voted false
  final Set<String> agreeVoterIds; // Track users who voted agree
  final Set<String> disagreeVoterIds; // Track users who voted disagree

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
    this.agree = 0,
    this.disagree = 0,
    this.comments = const [],
    this.feedback,
    this.trueVoterIds = const {},
    this.falseVoterIds = const {},
    this.agreeVoterIds = const {},
    this.disagreeVoterIds = const {},
  });

  bool hasUserVotedTrue(String userId) => trueVoterIds.contains(userId);
  bool hasUserVotedFalse(String userId) => falseVoterIds.contains(userId);
  bool hasUserVotedAgree(String userId) => agreeVoterIds.contains(userId);
  bool hasUserVotedDisagree(String userId) => disagreeVoterIds.contains(userId);

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

  Post toggleAgreeVote(String voterId) {
    if (hasUserVotedAgree(voterId)) {
      return copyWith(
        agree: agree - 1,
        agreeVoterIds: Set<String>.from(agreeVoterIds)..remove(voterId),
      );
    } else {
      return copyWith(
        agree: agree + 1,
        disagree: hasUserVotedDisagree(voterId) ? disagree - 1 : disagree,
        agreeVoterIds: Set<String>.from(agreeVoterIds)..add(voterId),
        disagreeVoterIds: Set<String>.from(disagreeVoterIds)..remove(voterId),
      );
    }
  }

  Post toggleDisagreeVote(String voterId) {
    if (hasUserVotedDisagree(voterId)) {
      return copyWith(
        disagree: disagree - 1,
        disagreeVoterIds: Set<String>.from(disagreeVoterIds)..remove(voterId),
      );
    } else {
      return copyWith(
        disagree: disagree + 1,
        agree: hasUserVotedAgree(voterId) ? agree - 1 : agree,
        disagreeVoterIds: Set<String>.from(disagreeVoterIds)..add(voterId),
        agreeVoterIds: Set<String>.from(agreeVoterIds)..remove(voterId),
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
    int? agree,
    int? disagree,
    List<Comment>? comments,
    AuthorityFeedback? feedback,
    Set<String>? trueVoterIds,
    Set<String>? falseVoterIds,
    Set<String>? agreeVoterIds,
    Set<String>? disagreeVoterIds,
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
        agree,
        disagree,
        comments,
        feedback,
        trueVoterIds,
        falseVoterIds,
        agreeVoterIds,
        disagreeVoterIds,
      ];
}