// lib/presentation/bloc/auth/auth_bloc.dart

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/usecases/create_user_profile.dart';
import 'package:campus_saga/domain/usecases/sign_up_user.dart';
import 'package:campus_saga/domain/usecases/upload_user_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../domain/usecases/get_user_profile.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetUserProfile getUserProfile;
  final UploadUserImage uploadUserImage;
  final SignUpUser signUpUser;
  final CreateUserProfile createUserProfile;

  AuthBloc({
    required this.getUserProfile,
    required this.uploadUserImage,
    required this.signUpUser,
    required this.createUserProfile,
  }) : super(AuthInitial()) {
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

    on<SignUpEvent>((event, emit) async {
      emit(AuthLoading());
      String imageUrl = "https://loremflickr.com/200/200?random=1";

      try {
        final isSignedUp = await signUpUser(
          UserParams(
            email: event.email,
            password: event.password,
          ),
        );
        isSignedUp.fold((failure) => emit(AuthFailure(failure.message)),
            (userId) async {
          //Update the database with the user's profile image and id
          final isUploaded = await uploadUserImage(userId, event.image!);
          isUploaded.fold(
            (failure) {
              createUserProfile(User(
                id: userId,
                name: event.username,
                email: event.email,
                universityId: event.university,
                userType: UserType.student,
                profilePictureUrl: imageUrl,
              ));
            },
            (url) async {
              createUserProfile(User(
                id: userId,
                name: event.username,
                email: event.email,
                universityId: event.university,
                userType: UserType.student,
                profilePictureUrl: url,
              ));
            },
          );
        });

        emit(AuthSuccess());
      } catch (_) {
        emit(AuthFailure('Sign-up failed. Please try again.'));
      }
    });

    on<SignInEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        // Implement login logic here
        await Future.delayed(Duration(seconds: 2));
        emit(AuthSuccess());
      } catch (_) {
        emit(AuthFailure('Login failed. Incorrect credentials.'));
      }
    });
  }
}
