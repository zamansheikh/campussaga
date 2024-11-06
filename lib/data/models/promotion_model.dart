// lib/data/models/promotion_model.dart

import 'package:campus_saga/domain/entities/promotion.dart';

class PromotionModel extends Promotion {
  const PromotionModel({
    required String id,
    required String userId,
    required String universityId,
    required String promotionTitle,
    required String description,
    required String clubName,
    required DateTime timestamp,
    DateTime? expiryDate,
    List<String> imageUrls = const [],
    String? eventLink,
    int likes = 0,
    int dislikes = 0,
    Set<String> likeVoterIds = const {},
    Set<String> dislikeVoterIds = const {},
  }) : super(
          id: id,
          userId: userId,
          universityId: universityId,
          promotionTitle: promotionTitle,
          description: description,
          clubName: clubName,
          timestamp: timestamp,
          expiryDate: expiryDate,
          imageUrls: imageUrls,
          eventLink: eventLink,
          likes: likes,
          dislikes: dislikes,
          likeVoterIds: likeVoterIds,
          dislikeVoterIds: dislikeVoterIds,
        );

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      universityId: json['universityId'] as String,
      promotionTitle: json['promotionTitle'] as String,
      description: json['description'] as String,
      clubName: json['clubName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      eventLink: json['eventLink'] as String?,
      likes: json['likes'] as int? ?? 0,
      dislikes: json['dislikes'] as int? ?? 0,
      likeVoterIds: (json['likeVoterIds'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? {},
      dislikeVoterIds: (json['dislikeVoterIds'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'universityId': universityId,
      'promotionTitle': promotionTitle,
      'description': description,
      'clubName': clubName,
      'timestamp': timestamp.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'imageUrls': imageUrls,
      'eventLink': eventLink,
      'likes': likes,
      'dislikes': dislikes,
      'likeVoterIds': likeVoterIds.toList(),
      'dislikeVoterIds': dislikeVoterIds.toList(),
    };
  }

  factory PromotionModel.fromEntity(Promotion promotion) {
    return PromotionModel(
      id: promotion.id,
      userId: promotion.userId,
      universityId: promotion.universityId,
      promotionTitle: promotion.promotionTitle,
      description: promotion.description,
      clubName: promotion.clubName,
      timestamp: promotion.timestamp,
      expiryDate: promotion.expiryDate,
      imageUrls: promotion.imageUrls,
      eventLink: promotion.eventLink,
      likes: promotion.likes,
      dislikes: promotion.dislikes,
      likeVoterIds: promotion.likeVoterIds,
      dislikeVoterIds: promotion.dislikeVoterIds,
    );
  }

  Promotion toEntity() {
    return Promotion(
      id: id,
      userId: userId,
      universityId: universityId,
      promotionTitle: promotionTitle,
      description: description,
      clubName: clubName,
      timestamp: timestamp,
      expiryDate: expiryDate,
      imageUrls: imageUrls,
      eventLink: eventLink,
      likes: likes,
      dislikes: dislikes,
      likeVoterIds: likeVoterIds,
      dislikeVoterIds: dislikeVoterIds,
    );
  }

  PromotionModel copyWith({
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
    return PromotionModel(
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
}