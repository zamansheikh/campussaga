// lib/domain/entities/university.dart

import 'package:equatable/equatable.dart';

class University extends Equatable {
  final String id;
  final String name;
  final String location;
  final bool isPublic;
  final double researchScore; // Public score, 40%
  final double qsRankingScore; // QS Ranking, 40%
  final int totalPosts; // App activity metric
  final int totalSolvedPosts; // App activity metric
  final int interactions; // App activity metric (e.g., likes, comments)

  const University({
    required this.id,
    required this.name,
    required this.location,
    required this.isPublic,
    required this.researchScore,
    required this.qsRankingScore,
    this.totalPosts = 0,
    this.totalSolvedPosts = 0,
    this.interactions = 0,
  });

  // Calculate the total ranking score with 80% public data and 20% app activity.
  double get rankingScore {
    double publicScore = 0.8 * ((0.5 * researchScore) + (0.5 * qsRankingScore));
    double appActivityScore = 0.2 * (totalPosts * 0.5 + totalSolvedPosts * 0.3 + interactions * 0.2);
    return publicScore + appActivityScore;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        isPublic,
        researchScore,
        qsRankingScore,
        totalPosts,
        totalSolvedPosts,
        interactions,
      ];
}