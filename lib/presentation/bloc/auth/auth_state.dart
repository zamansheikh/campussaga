// lib/presentation/bloc/auth/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthUpdateFailure extends AuthState {
  final String message;

  const AuthUpdateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted after Google sign-in when the user profile lacks essential info
/// (university, department, gender). The partial user is carried along.
class AuthProfileIncomplete extends AuthState {
  final User user;

  const AuthProfileIncomplete(this.user);

  @override
  List<Object?> get props => [user];
}
