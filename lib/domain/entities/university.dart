import 'package:equatable/equatable.dart';

class University extends Equatable {
  final String id;
  final String name;
  final String location;
  final bool isPublic;
  final double researchScore;
  final double qsRankingScore;
  final int totalPosts;
  final int totalSolvedPosts;
  final int interactions;
  final int studentCount;
  final int facultyCount;
  final int programsOffered;
  final int establishmentYear;
  final double academicScore;
  final double satisfactionScore;

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
    this.studentCount = 0,
    this.facultyCount = 0,
    this.programsOffered = 0,
    this.establishmentYear = 0,
    this.academicScore = 0.0,
    this.satisfactionScore = 0.0,
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
        studentCount,
        facultyCount,
        programsOffered,
        establishmentYear,
        academicScore,
        satisfactionScore,
      ];
}
