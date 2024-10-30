// lib/presentation/bloc/auth/auth_event.dart

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

class AuthLogoutRequested extends AuthEvent {}
