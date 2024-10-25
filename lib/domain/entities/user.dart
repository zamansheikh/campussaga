// lib/domain/entities/user.dart

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String universityId;
  final bool isVerified;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.universityId,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [id, name, email, universityId, isVerified];
}
