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
  final int agrees;
  final int disagrees;
  final int studentCount;
  final int facultyCount;
  final int programsOffered;
  final int establishmentYear;
  final double academicScore;

  const University({
    required this.id,
    required this.name,
    required this.location,
    required this.isPublic,
    required this.researchScore,
    required this.qsRankingScore,
    this.totalPosts = 0,
    this.totalSolvedPosts = 0,
    this.agrees = 0,
    this.disagrees = 0,
    this.studentCount = 0,
    this.facultyCount = 0,
    this.programsOffered = 0,
    this.establishmentYear = 0,
    this.academicScore = 0.0,
  });

  // Calculate the total ranking score with 80% public data and 20% app activity.
  double get rankingScore {
    double publicScore = 0.8 * ((0.5 * researchScore) + (0.5 * qsRankingScore));
    double appActivityScore = 0.2 * satisfactionPercentage;
    return publicScore + appActivityScore;
  }

  // Calculate the satisfaction score as a percentage (0 to 100)
  double get satisfactionPercentage {
    double likeDislikeRatio = agrees / (agrees + disagrees);
    double solvePostRatio = totalSolvedPosts / totalPosts;
    return (likeDislikeRatio + solvePostRatio) / 2 * 100;
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
    agrees,
    disagrees,
    studentCount,
    facultyCount,
    programsOffered,
    establishmentYear,
    academicScore,
  ];
}