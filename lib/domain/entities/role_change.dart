import 'package:equatable/equatable.dart';

class RoleChange extends Equatable {
  final String role;
  final String email;
  final String uuid;
  final String userName;
  final String phoneNumber;
  final String profilePicture;
  final String status;
  final DateTime timestamp;

  RoleChange({
    required this.role,
    required this.email,
    required this.uuid,
    required this.userName,
    required this.phoneNumber,
    required this.profilePicture,
    required this.status,
    required this.timestamp,
  });

  RoleChange copyWith({
    String? role,
    String? email,
    String? uuid,
    String? userName,
    String? phoneNumber,
    String? profilePicture,
    String? status,
    DateTime? timestamp,
  }) {
    return RoleChange(
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

  @override
  List<Object?> get props => [
        role,
        email,
        uuid,
        userName,
        phoneNumber,
        profilePicture,
        status,
        timestamp,
      ];
}