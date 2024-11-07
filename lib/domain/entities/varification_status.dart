// lib/domain/entities/verification.dart

import 'package:equatable/equatable.dart';

enum VerificationStatus {
  pending,
  rejected,
  fake,
  restricted,
  verified,
}

class Verification extends Equatable {
  final String userUuid;
  final String universityEmail;
  final String universityIdCardPhotoUrl;
  final String profilePhotoUrl; // New field for profile photo URL
  final VerificationStatus status;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String department;
  final String gender;
  final DateTime timestamp ;

  const Verification({
    required this.userUuid,
    required this.universityEmail,
    required this.universityIdCardPhotoUrl,
    required this.profilePhotoUrl, // Added to constructor
    required this.status,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.department,
    required this.gender,
    required this.timestamp,
  });

  //Make a copyWith method to update all the fields of the Verification object
  Verification copyWith({
    String? userUuid,
    String? universityEmail,
    String? universityIdCardPhotoUrl,
    String? profilePhotoUrl,
    VerificationStatus? status,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? department,
    String? gender,
    DateTime? timestamp,
  }) {
    return Verification(
      userUuid: userUuid ?? this.userUuid,
      universityEmail: universityEmail ?? this.universityEmail,
      universityIdCardPhotoUrl: universityIdCardPhotoUrl ?? this.universityIdCardPhotoUrl,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      department: department ?? this.department,
      gender: gender ?? this.gender,
      timestamp: this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        userUuid,
        universityEmail,
        universityIdCardPhotoUrl,
        profilePhotoUrl,
        status,
        phoneNumber,
        dateOfBirth,
        department,
        gender,
        timestamp,
      ];
}
