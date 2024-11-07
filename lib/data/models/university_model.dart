import 'package:campus_saga/domain/entities/university.dart';

class UniversityModel extends University {
  const UniversityModel({
    required String id,
    required String name,
    required String location,
    required bool isPublic,
    required double researchScore,
    required double qsRankingScore,
    int totalPosts = 0,
    int totalSolvedPosts = 0,
    int agrees = 0,
    int disagrees = 0,
    int studentCount = 0,
    int facultyCount = 0,
    int programsOffered = 0,
    int establishmentYear = 0,
    double academicScore = 0.0,
  }) : super(
          id: id,
          name: name,
          location: location,
          isPublic: isPublic,
          researchScore: researchScore,
          qsRankingScore: qsRankingScore,
          totalPosts: totalPosts,
          totalSolvedPosts: totalSolvedPosts,
          agrees: agrees,
          disagrees: disagrees,
          studentCount: studentCount,
          facultyCount: facultyCount,
          programsOffered: programsOffered,
          establishmentYear: establishmentYear,
          academicScore: academicScore,
        );

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      isPublic: json['isPublic'] as bool,
      researchScore: (json['researchScore'] as num).toDouble(),
      qsRankingScore: (json['qsRankingScore'] as num).toDouble(),
      totalPosts: json['totalPosts'] as int? ?? 0,
      totalSolvedPosts: json['totalSolvedPosts'] as int? ?? 0,
      agrees: json['agrees'] as int? ?? 0,
      disagrees: json['disagrees'] as int? ?? 0,
      studentCount: json['studentCount'] as int? ?? 0,
      facultyCount: json['facultyCount'] as int? ?? 0,
      programsOffered: json['programsOffered'] as int? ?? 0,
      establishmentYear: json['establishmentYear'] as int? ?? 0,
      academicScore: (json['academicScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'isPublic': isPublic,
      'researchScore': researchScore,
      'qsRankingScore': qsRankingScore,
      'totalPosts': totalPosts,
      'totalSolvedPosts': totalSolvedPosts,
      'agrees': agrees,
      'disagrees': disagrees,
      'studentCount': studentCount,
      'facultyCount': facultyCount,
      'programsOffered': programsOffered,
      'establishmentYear': establishmentYear,
      'academicScore': academicScore,
    };
  }

  factory UniversityModel.fromEntity(University university) {
    return UniversityModel(
      id: university.id,
      name: university.name,
      location: university.location,
      isPublic: university.isPublic,
      researchScore: university.researchScore,
      qsRankingScore: university.qsRankingScore,
      totalPosts: university.totalPosts,
      totalSolvedPosts: university.totalSolvedPosts,
      agrees: university.agrees,
      disagrees: university.disagrees,
      studentCount: university.studentCount,
      facultyCount: university.facultyCount,
      programsOffered: university.programsOffered,
      establishmentYear: university.establishmentYear,
      academicScore: university.academicScore,
    );
  }

  University toEntity() {
    return University(
      id: id,
      name: name,
      location: location,
      isPublic: isPublic,
      researchScore: researchScore,
      qsRankingScore: qsRankingScore,
      totalPosts: totalPosts,
      totalSolvedPosts: totalSolvedPosts,
      agrees: agrees,
      disagrees: disagrees,
      studentCount: studentCount,
      facultyCount: facultyCount,
      programsOffered: programsOffered,
      establishmentYear: establishmentYear,
      academicScore: academicScore,
    );
  }

  UniversityModel copyWith({
    String? id,
    String? name,
    String? location,
    bool? isPublic,
    double? researchScore,
    double? qsRankingScore,
    int? totalPosts,
    int? totalSolvedPosts,
    int? agrees,
    int? disagrees,
    int? studentCount,
    int? facultyCount,
    int? programsOffered,
    int? establishmentYear,
    double? academicScore,
  }) {
    return UniversityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      isPublic: isPublic ?? this.isPublic,
      researchScore: researchScore ?? this.researchScore,
      qsRankingScore: qsRankingScore ?? this.qsRankingScore,
      totalPosts: totalPosts ?? this.totalPosts,
      totalSolvedPosts: totalSolvedPosts ?? this.totalSolvedPosts,
      agrees: agrees ?? this.agrees,
      disagrees: disagrees ?? this.disagrees,
      studentCount: studentCount ?? this.studentCount,
      facultyCount: facultyCount ?? this.facultyCount,
      programsOffered: programsOffered ?? this.programsOffered,
      establishmentYear: establishmentYear ?? this.establishmentYear,
      academicScore: academicScore ?? this.academicScore,
    );
  }
}