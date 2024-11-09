import 'package:campus_saga/domain/entities/role_change.dart';

class RoleChangeModel extends RoleChange {
  RoleChangeModel({
    required String role,
    required String email,
    required String uuid,
    required String userName,
    required String phoneNumber,
    required String profilePicture,
    required String status,
    required DateTime timestamp,
  }) : super(
          role: role,
          email: email,
          uuid: uuid,
          userName: userName,
          phoneNumber: phoneNumber,
          profilePicture: profilePicture,
          status: status,
          timestamp: timestamp,
        );

  factory RoleChangeModel.fromJson(Map<String, dynamic> json) {
    return RoleChangeModel(
      role: json['role'] as String,
      email: json['email'] as String,
      uuid: json['uuid'] as String,
      userName: json['userName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      profilePicture: json['profilePicture'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'email': email,
      'uuid': uuid,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RoleChangeModel.fromEntity(RoleChange roleChange) {
    return RoleChangeModel(
      role: roleChange.role,
      email: roleChange.email,
      uuid: roleChange.uuid,
      userName: roleChange.userName,
      phoneNumber: roleChange.phoneNumber,
      profilePicture: roleChange.profilePicture,
      status: roleChange.status,
      timestamp: roleChange.timestamp,
    );
  }

  RoleChange toEntity() {
    return RoleChange(
      role: role,
      email: email,
      uuid: uuid,
      userName: userName,
      phoneNumber: phoneNumber,
      profilePicture: profilePicture,
      status: status,
      timestamp: timestamp,
    );
  }

  RoleChangeModel copyWith({
    String? role,
    String? email,
    String? uuid,
    String? userName,
    String? phoneNumber,
    String? profilePicture,
    String? status,
    DateTime? timestamp,
  }) {
    return RoleChangeModel(
      role: role ?? this.role,
      email: email ?? this.email,
      uuid: uuid ?? this.uuid,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
