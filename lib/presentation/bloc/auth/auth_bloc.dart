// lib/presentation/bloc/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../domain/usecases/get_user_profile.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetUserProfile getUserProfile;

  AuthBloc({required this.getUserProfile}) : super(AuthInitial()) {
    on<AuthRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await getUserProfile(event.userId);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<AuthLogoutRequested>((event, emit) async {
      emit(AuthLoading());
      // You might call a use case to handle logout here if required
      emit(AuthUnauthenticated());
    });
  }
}
