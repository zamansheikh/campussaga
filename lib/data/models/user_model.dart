// lib/data/models/user_model.dart

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String name,
    required String email,
    required String universityId,
    bool isVerified = false,
    required UserType userType,
    required String profilePictureUrl,
  }) : super(
          id: id,
          name: name,
          email: email,
          universityId: universityId,
          isVerified: isVerified,
          userType: userType,
          profilePictureUrl: profilePictureUrl,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      universityId: json['universityId'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      userType: UserType.values.firstWhere((e) => e.toString() == 'UserType.${json['userType']}'),
      profilePictureUrl: json['profilePictureUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'universityId': universityId,
      'isVerified': isVerified,
      'userType': userType.toString().split('.').last,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}