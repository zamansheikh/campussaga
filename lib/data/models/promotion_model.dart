// lib/data/models/promotion_model.dart

import 'package:campus_saga/domain/entities/promotion.dart';

class PromotionModel extends Promotion {
  const PromotionModel({
    required String id,
    required String userId,
    required String universityId,
    required String promotionTitle,
    required String description,
    required DateTime timestamp,
    List<String> imageUrls = const [],
    int trueVotes = 0,
    int falseVotes = 0,
    Set<String> trueVoterIds = const {},
    Set<String> falseVoterIds = const {},
  }) : super(
          id: id,
          userId: userId,
          universityId: universityId,
          promotionTitle: promotionTitle,
          description: description,
          timestamp: timestamp,
          imageUrls: imageUrls,
          trueVotes: trueVotes,
          falseVotes: falseVotes,
          trueVoterIds: trueVoterIds,
          falseVoterIds: falseVoterIds,
        );

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      universityId: json['universityId'] as String,
      promotionTitle: json['promotionTitle'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      trueVotes: json['trueVotes'] as int? ?? 0,
      falseVotes: json['falseVotes'] as int? ?? 0,
      trueVoterIds: (json['trueVoterIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      falseVoterIds: (json['falseVoterIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'universityId': universityId,
      'promotionTitle': promotionTitle,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
      'trueVotes': trueVotes,
      'falseVotes': falseVotes,
      'trueVoterIds': trueVoterIds.toList(),
      'falseVoterIds': falseVoterIds.toList(),
    };
  }

  factory PromotionModel.fromEntity(Promotion promotion) {
    return PromotionModel(
      id: promotion.id,
      userId: promotion.userId,
      universityId: promotion.universityId,
      promotionTitle: promotion.promotionTitle,
      description: promotion.description,
      timestamp: promotion.timestamp,
      imageUrls: promotion.imageUrls,
      trueVotes: promotion.trueVotes,
      falseVotes: promotion.falseVotes,
      trueVoterIds: promotion.trueVoterIds,
      falseVoterIds: promotion.falseVoterIds,
    );
  }

  Promotion toEntity() {
    return Promotion(
      id: id,
      userId: userId,
      universityId: universityId,
      promotionTitle: promotionTitle,
      description: description,
      timestamp: timestamp,
      imageUrls: imageUrls,
      trueVotes: trueVotes,
      falseVotes: falseVotes,
      trueVoterIds: trueVoterIds,
      falseVoterIds: falseVoterIds,
    );
  }

  PromotionModel copyWith({
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
    return PromotionModel(
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
}
