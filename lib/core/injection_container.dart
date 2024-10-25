// lib/core/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import '../data/datasources/firebase_datasource.dart';
// import '../data/repositories/user_repository_impl.dart';
// import '../data/repositories/post_repository_impl.dart';
// import '../domain/repositories/user_repository.dart';
// import '../domain/repositories/post_repository.dart';
// import '../domain/usecases/get_user_profile.dart';
// import '../domain/usecases/create_post.dart';
// import '../presentation/bloc/auth/auth_bloc.dart';
// import '../presentation/bloc/post/post_bloc.dart';

final sl = GetIt.instance; // Service locator

Future<void> init() async {
  // Firebase services
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Data sources
  // sl.registerLazySingleton<FirebaseDataSource>(
  //   () => FirebaseDataSourceImpl(
  //     auth: sl(),
  //     firestore: sl(),
  //   ),
  // );

  // Repositories
  // sl.registerLazySingleton<UserRepository>(
  //   () => UserRepositoryImpl(dataSource: sl()),
  // );
  // sl.registerLazySingleton<PostRepository>(
  //   () => PostRepositoryImpl(dataSource: sl()),
  // );

  // Use cases
  // sl.registerLazySingleton(() => GetUserProfile(sl()));
  // sl.registerLazySingleton(() => CreatePost(sl()));

  // BLoCs
  // sl.registerFactory(() => AuthBloc(getUserProfile: sl()));
  // sl.registerFactory(() => PostBloc(createPost: sl(), postRepository: sl()));
}
