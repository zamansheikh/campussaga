import 'package:equatable/equatable.dart';

class Promotion extends Equatable {
  final String id;
  final String userId;
  final String universityId;
  final String promotionTitle;
  final String description;
  final String clubName;
  final DateTime timestamp;
  final DateTime? expiryDate;
  final List<String> imageUrls;
  final String? eventLink;
  final int likes;
  final int dislikes;
  final Set<String> likeVoterIds; // Track users who voted true
  final Set<String> dislikeVoterIds; // Track users who voted false

  const Promotion({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.promotionTitle,
    required this.description,
    required this.clubName,
    required this.timestamp,
    this.expiryDate,
    this.imageUrls = const [],
    this.eventLink,
    this.likes = 0,
    this.dislikes = 0,
    this.likeVoterIds = const {},
    this.dislikeVoterIds = const {},
  });

  bool hasUserVotedTrue(String userId) => likeVoterIds.contains(userId);
  bool hasUserVotedFalse(String userId) => dislikeVoterIds.contains(userId);

  Promotion toggleTrueVote(String voterId) {
    if (hasUserVotedTrue(voterId)) {
      return copyWith(
        likes: likes - 1,
        likeVoterIds: Set<String>.from(likeVoterIds)..remove(voterId),
      );
    } else {
      return copyWith(
        likes: likes + 1,
        dislikes: hasUserVotedFalse(voterId) ? dislikes - 1 : dislikes,
        likeVoterIds: Set<String>.from(likeVoterIds)..add(voterId),
        dislikeVoterIds: Set<String>.from(dislikeVoterIds)..remove(voterId),
      );
    }
  }

  Promotion toggleFalseVote(String voterId) {
    if (hasUserVotedFalse(voterId)) {
      return copyWith(
        dislikes: dislikes - 1,
        dislikeVoterIds: Set<String>.from(dislikeVoterIds)..remove(voterId),
      );
    } else {
      return copyWith(
        dislikes: dislikes + 1,
        likes: hasUserVotedTrue(voterId) ? likes - 1 : likes,
        dislikeVoterIds: Set<String>.from(dislikeVoterIds)..add(voterId),
        likeVoterIds: Set<String>.from(likeVoterIds)..remove(voterId),
      );
    }
  }

  Promotion copyWith({
    String? id,
    String? userId,
    String? universityId,
    String? promotionTitle,
    String? description,
    String? clubName,
    DateTime? timestamp,
    DateTime? expiryDate,
    List<String>? imageUrls,
    String? eventLink,
    int? likes,
    int? dislikes,
    Set<String>? likeVoterIds,
    Set<String>? dislikeVoterIds,
  }) {
    return Promotion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      universityId: universityId ?? this.universityId,
      promotionTitle: promotionTitle ?? this.promotionTitle,
      description: description ?? this.description,
      clubName: clubName ?? this.clubName,
      timestamp: timestamp ?? this.timestamp,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrls: imageUrls ?? this.imageUrls,
      eventLink: eventLink ?? this.eventLink,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      likeVoterIds: likeVoterIds ?? this.likeVoterIds,
      dislikeVoterIds: dislikeVoterIds ?? this.dislikeVoterIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        universityId,
        promotionTitle,
        description,
        clubName,
        timestamp,
        expiryDate,
        imageUrls,
        eventLink,
        likes,
        dislikes,
        likeVoterIds,
        dislikeVoterIds,
      ];
}
