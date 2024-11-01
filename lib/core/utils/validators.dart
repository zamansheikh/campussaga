// lib/core/utils/validators.dart

import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/user.dart';

class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  static bool isNonEmpty(String value) {
    return value.isNotEmpty;
  }

  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^\d{10}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  static bool isValidAuthority(Post post, User user) {
    return post.universityId == user.universityId.split('@').last.trim() &&
        user.isVerified &&
        user.userType == UserType.university;
  }

  static bool isValidStudent(User user, Post post) {
    return user.isVerified &&
        user.userType == UserType.student &&
        post.universityId == user.universityId.split('@').last.trim();
  }

  static bool isValidAdmin(User user, Post post) {
    return user.isVerified &&
        user.userType == UserType.admin &&
        post.universityId == user.universityId.split('@').last.trim();
  }

  static bool isSuperAdmin(User user) {
    return user.isVerified && user.userType == UserType.admin;
  }
}
