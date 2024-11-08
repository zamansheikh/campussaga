// lib/presentation/bloc/auth/auth_event.dart

import 'dart:io';

import 'package:campus_saga/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthRequested extends AuthEvent {
  final String userId;

  const AuthRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AuthUpdateRequested extends AuthEvent {
  final User user;

  const AuthUpdateRequested(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthLogoutRequested extends AuthEvent {}

class SignUpEvent extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String university;
  final File? image;

  SignUpEvent({
    required this.username,
    required this.email,
    required this.password,
    required this.university,
    this.image,
  });
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent({required this.email, required this.password});
}

class AuthRefreshRequested extends AuthEvent {}

class SignOutEvent extends AuthEvent {}