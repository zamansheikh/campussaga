import 'package:equatable/equatable.dart';

class Promotion extends Equatable {
  final String id;
  final String userId;
  final String universityId;
  final String promotionTitle;
  final String description;
  final DateTime timestamp;
  final List<String> imageUrls;
  final int trueVotes;
  final int falseVotes;
  final Set<String> trueVoterIds; // Track users who voted true
  final Set<String> falseVoterIds; // Track users who voted false

  const Promotion({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.promotionTitle,
    required this.description,
    required this.timestamp,
    this.imageUrls = const [],
    this.trueVotes = 0,
    this.falseVotes = 0,
    this.trueVoterIds = const {},
    this.falseVoterIds = const {},
  });

  bool hasUserVotedTrue(String userId) => trueVoterIds.contains(userId);
  bool hasUserVotedFalse(String userId) => falseVoterIds.contains(userId);

  Promotion toggleTrueVote(String voterId) {
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

  Promotion toggleFalseVote(String voterId) {
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

  Promotion copyWith({
    String? id,
    String? userId,
    String? universityId,
    String? promotionTitle,
    String? description,
    DateTime? timestamp,
    List<String>? imageUrls,
    int? trueVotes,
    int? falseVotes,
    Set<String>? trueVoterIds,
    Set<String>? falseVoterIds,
  }) {
    return Promotion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      universityId: universityId ?? this.universityId,
      promotionTitle: promotionTitle ?? this.promotionTitle,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      imageUrls: imageUrls ?? this.imageUrls,
      trueVotes: trueVotes ?? this.trueVotes,
      falseVotes: falseVotes ?? this.falseVotes,
      trueVoterIds: trueVoterIds ?? this.trueVoterIds,
      falseVoterIds: falseVoterIds ?? this.falseVoterIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        universityId,
        promotionTitle,
        description,
        timestamp,
        imageUrls,
        trueVotes,
        falseVotes,
        trueVoterIds,
        falseVoterIds,
      ];
}
