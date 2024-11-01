// lib/core/injection_container.dart
import 'package:campus_saga/core/services/auth_service.dart';
import 'package:campus_saga/data/datasources/remote/firebase_datasource.dart';
import 'package:campus_saga/data/repositories/post_repository_impl.dart';
import 'package:campus_saga/data/repositories/user_repository_impl.dart';
import 'package:campus_saga/domain/repositories/post_repository.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:campus_saga/domain/usecases/create_user_profile.dart';
import 'package:campus_saga/domain/usecases/sign_in_user.dart';
import 'package:campus_saga/domain/usecases/sign_out_user.dart';
import 'package:campus_saga/domain/usecases/sign_up_user.dart';
import 'package:campus_saga/domain/usecases/upload_user_image.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/post/post_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/usecases/create_post.dart';
import '../domain/usecases/get_user_profile.dart';

final sl = GetIt.instance; // Service locator

Future<void> init() async {
  // Firebase services
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // Data sources
  sl.registerLazySingleton<FirebaseDataSource>(
    () => FirebaseDataSource(
      firebaseAuth: sl(),
      firestore: sl(),
      firebaseStorage: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUserProfile(sl()));
  sl.registerLazySingleton(() => CreatePost(sl()));
  sl.registerLazySingleton(() => UploadUserImage(sl()));
  sl.registerLazySingleton(() => SignUpUser(sl()));
  sl.registerLazySingleton(() => CreateUserProfile(sl()));
  sl.registerLazySingleton(() => SignOutUser(sl()));
  sl.registerLazySingleton(() => SignInUser(sl()));

  // BLoCs
  sl.registerLazySingleton(() => AuthBloc(
        getUserProfile: sl(),
        uploadUserImage: sl(),
        signUpUser: sl(),
        createUserProfile: sl(),
        signOutUser: sl(),
        signInUser: sl(),
      ));
  sl.registerFactory(() => PostBloc(
        createPost: sl(),
      ));

  //Auth Service
  sl.registerLazySingleton(() => AuthService());
}
