// lib/domain/entities/user.dart

import 'package:equatable/equatable.dart';

enum UserType { student, university, admin }

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String universityId;
  final bool isVerified;
  final UserType userType;
  final String profilePictureUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.universityId,
    this.isVerified = false,
    required this.userType,
    required this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [id, name, email, universityId, isVerified, userType, profilePictureUrl];
}