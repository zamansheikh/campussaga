// lib/domain/entities/user.dart

import 'package:equatable/equatable.dart';

enum UserType { student, university, admin }

enum UserBadge { newbie, active, expert, hero, legend }

enum AchievementType { postCreator, issueResolver, helpfulVoter, trendSetter }

enum Department {
  cse,
  swe,
  eee,
  civil,
  bba,
  english,
  law,
  pharmacy,
  architecture,
  other
}

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String universityId;
  final bool isVerified;
  final UserType userType;
  final String profilePictureUrl;

  // Engagement metrics
  final int postCount;
  final int commentCount;
  final int resolvedIssuesCount;
  final int receivedVotesCount;
  final int givenVotesCount;
  final double reputationScore;
  final UserBadge currentBadge;
  final List<AchievementType> achievements;
  final int streakDays;
  final Map<String, int> activityLog; // Monthly activity tracking

  // Optional student-specific fields
  final String? studentId;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final List<String>? clubNames;
  final Department? department;
  final int? batch;
  final double? cgpa;
  final String? currentSemester;
  final String? bloodGroup;
  final String? address;
  final String? guardianPhone;
  final List<String>? skills;
  final List<String>? interests;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.universityId,
    this.isVerified = false,
    required this.userType,
    required this.profilePictureUrl,
    this.postCount = 0,
    this.commentCount = 0,
    this.resolvedIssuesCount = 0,
    this.receivedVotesCount = 0,
    this.givenVotesCount = 0,
    this.reputationScore = 0.0,
    this.currentBadge = UserBadge.newbie,
    this.achievements = const [],
    this.streakDays = 0,
    this.activityLog = const {},
    // Student-specific fields
    this.studentId,
    this.dateOfBirth,
    this.phoneNumber,
    this.clubNames,
    this.department,
    this.batch,
    this.cgpa,
    this.currentSemester,
    this.bloodGroup,
    this.address,
    this.guardianPhone,
    this.skills,
    this.interests,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        universityId,
        isVerified,
        userType,
        profilePictureUrl,
        postCount,
        commentCount,
        resolvedIssuesCount,
        receivedVotesCount,
        givenVotesCount,
        reputationScore,
        currentBadge,
        achievements,
        streakDays,
        activityLog,
        // Student-specific fields
        studentId,
        dateOfBirth,
        phoneNumber,
        clubNames,
        department,
        batch,
        cgpa,
        currentSemester,
        bloodGroup,
        address,
        guardianPhone,
        skills,
        interests,
      ];
}
