// lib/presentation/bloc/auth/auth_bloc.dart

import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/domain/usecases/create_user_profile.dart';
import 'package:campus_saga/domain/usecases/sign_in_user.dart';
import 'package:campus_saga/domain/usecases/sign_out_user.dart';
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
  final SignOutUser signOutUser;
  final SignInUser signInUser;

  AuthBloc({
    required this.getUserProfile,
    required this.uploadUserImage,
    required this.signUpUser,
    required this.createUserProfile,
    required this.signOutUser,
    required this.signInUser,
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

      try {
        final isSignedUp = await signUpUser(
          UserParams(
            email: event.email,
            password: event.password,
          ),
        );

        await isSignedUp.fold(
          (failure) async {
            emit(AuthFailure(failure.message));
          },
          (userId) async {
            final isUploaded = await uploadUserImage(userId, event.image!);
            await isUploaded.fold(
              (failure) async {
                emit(AuthFailure(failure.message));
              },
              (imageUrl) async {
                final isDatabaseUpdated = await createUserProfile(User(
                  id: userId,
                  name: event.username,
                  email: event.email,
                  universityId: event.university,
                  userType: UserType.student,
                  profilePictureUrl: imageUrl,
                ));
                await isDatabaseUpdated.fold(
                  (failure) async {
                    emit(AuthFailure(failure.message));
                  },
                  (_) async {
                    emit(AuthSuccess());
                    final user = await getUserProfile(userId);
                    user.fold(
                      (failure) {
                        emit(AuthUnauthenticated());
                      },
                      (user) {
                        emit(AuthAuthenticated(user));
                      },
                    );
                  },
                );
              },
            );
          },
        );
      } catch (e) {
        emit(AuthFailure('Sign-up failed. Please try again.'));
      }
    });
    on<SignInEvent>((event, emit) async {
      emit(AuthLoading());

      final result = await signInUser(UserParams(
        email: event.email,
        password: event.password,
      ));
      await result.fold((failure) async {
        emit(AuthFailure(failure.message));
      }, (userId) async {
        emit(AuthSuccess());
        final user = await getUserProfile(userId);
        await user.fold(
          (failure) async {
            emit(AuthFailure(failure.message));
          },
          (user) async {
            emit(AuthAuthenticated(user));
          },
        );
      });
    });

    on<SignOutEvent>((event, emit) async {
      emit(AuthLoading());

      final result = await signOutUser(NoParams());
      result.fold((failure) {
        emit(AuthFailure(failure.message));
      }, (_) {
        emit(AuthUnauthenticated());
      });
      await Future.delayed(Duration(seconds: 2));
      emit(AuthUnauthenticated());
    });

    on<AuthUpdateRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await createUserProfile(event.user);
      result.fold(
        (failure) => emit(AuthUpdateFailure(failure.message)),
        (user) => emit(AuthAuthenticated(event.user)),
      );
    });
  }
}
