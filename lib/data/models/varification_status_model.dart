import 'package:campus_saga/domain/entities/varification_status.dart';

class VerificationStatusModel extends Verification {
  const VerificationStatusModel({
    required String userUuid,
    required String universityEmail,
    required String universityIdCardPhotoUrl,
    required String profilePhotoUrl,
    required VerificationStatus status,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String department,
    required String gender,
    required DateTime timestamp,
  }) : super(
          userUuid: userUuid,
          universityEmail: universityEmail,
          universityIdCardPhotoUrl: universityIdCardPhotoUrl,
          profilePhotoUrl: profilePhotoUrl,
          status: status,
          phoneNumber: phoneNumber,
          dateOfBirth: dateOfBirth,
          department: department,
          gender: gender,
          timestamp: timestamp,
        );

  factory VerificationStatusModel.fromJson(Map<String, dynamic> json) {
    return VerificationStatusModel(
      userUuid: json['userUuid'] as String,
      universityEmail: json['universityEmail'] as String,
      universityIdCardPhotoUrl: json['universityIdCardPhotoUrl'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String,
      status: VerificationStatus.values.firstWhere(
        (e) => e.toString() == 'VerificationStatus.${json['status']}',
      ),
      phoneNumber: json['phoneNumber'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      department: json['department'] as String,
      gender: json['gender'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userUuid': userUuid,
      'universityEmail': universityEmail,
      'universityIdCardPhotoUrl': universityIdCardPhotoUrl,
      'profilePhotoUrl': profilePhotoUrl,
      'status': status.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'department': department,
      'gender': gender,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VerificationStatusModel.fromEntity(Verification verification) {
    return VerificationStatusModel(
      userUuid: verification.userUuid,
      universityEmail: verification.universityEmail,
      universityIdCardPhotoUrl: verification.universityIdCardPhotoUrl,
      profilePhotoUrl: verification.profilePhotoUrl,
      status: verification.status,
      phoneNumber: verification.phoneNumber,
      dateOfBirth: verification.dateOfBirth,
      department: verification.department,
      gender: verification.gender,
      timestamp: verification.timestamp,
    );
  }

  Verification toEntity() {
    return Verification(
      userUuid: userUuid,
      universityEmail: universityEmail,
      universityIdCardPhotoUrl: universityIdCardPhotoUrl,
      profilePhotoUrl: profilePhotoUrl,
      status: status,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      department: department,
      gender: gender,
      timestamp: timestamp,
    );
  }

  VerificationStatusModel copyWith({
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
    return VerificationStatusModel(
      userUuid: userUuid ?? this.userUuid,
      universityEmail: universityEmail ?? this.universityEmail,
      universityIdCardPhotoUrl:
          universityIdCardPhotoUrl ?? this.universityIdCardPhotoUrl,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      department: department ?? this.department,
      gender: gender ?? this.gender,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
