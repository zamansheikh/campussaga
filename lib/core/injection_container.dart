// lib/core/injection_container.dart
import 'package:campus_saga/core/services/auth_service.dart';
import 'package:campus_saga/data/datasources/remote/firebase_datasource.dart';
import 'package:campus_saga/data/repositories/post_repository_impl.dart';
import 'package:campus_saga/data/repositories/user_repository_impl.dart';
import 'package:campus_saga/domain/repositories/post_repository.dart';
import 'package:campus_saga/domain/repositories/user_repository.dart';
import 'package:campus_saga/domain/usecases/add_comment_usecase.dart';
import 'package:campus_saga/domain/usecases/add_feedback_usecase.dart';
import 'package:campus_saga/domain/usecases/add_universtity_usecase.dart';
import 'package:campus_saga/domain/usecases/add_vote_usecase.dart';
import 'package:campus_saga/domain/usecases/change_role_request.dart';
import 'package:campus_saga/domain/usecases/create_promotion.dart';
import 'package:campus_saga/domain/usecases/create_user_profile.dart';
import 'package:campus_saga/domain/usecases/create_varification_request_usecase.dart';
import 'package:campus_saga/domain/usecases/fetch_pending_verification_usecase.dart';
import 'package:campus_saga/domain/usecases/fetch_posts.dart';
import 'package:campus_saga/domain/usecases/fetch_promotion_usecase.dart';
import 'package:campus_saga/domain/usecases/fetch_role_change_usecase.dart';
import 'package:campus_saga/domain/usecases/fetch_university_usecase.dart';
import 'package:campus_saga/domain/usecases/sign_in_user.dart';
import 'package:campus_saga/domain/usecases/sign_out_user.dart';
import 'package:campus_saga/domain/usecases/sign_up_user.dart';
import 'package:campus_saga/domain/usecases/update_issue_post_usecase.dart';
import 'package:campus_saga/domain/usecases/update_promotion_usecase.dart';
import 'package:campus_saga/domain/usecases/update_user_role_usecase.dart';
import 'package:campus_saga/domain/usecases/update_verification_status_usecase.dart';
import 'package:campus_saga/domain/usecases/upload_post_images.dart';
import 'package:campus_saga/domain/usecases/upload_user_image.dart';
import 'package:campus_saga/domain/usecases/upload_verification_images_usecase.dart';
import 'package:campus_saga/presentation/bloc/admin/admin_bloc.dart';
import 'package:campus_saga/presentation/bloc/ads/ads_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/issue/issue_bloc.dart';
import 'package:campus_saga/presentation/bloc/post/post_bloc.dart';
import 'package:campus_saga/presentation/bloc/promotion/promotion_bloc.dart';
import 'package:campus_saga/presentation/bloc/role_manage/role_change_bloc.dart';
import 'package:campus_saga/presentation/bloc/university/university_bloc.dart';
import 'package:campus_saga/presentation/bloc/varify/varification_bloc.dart';
import 'package:campus_saga/presentation/bloc/verify_user/verify_user_bloc.dart';
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
  sl.registerLazySingleton(() => FetchPostsUsecase(sl()));
  sl.registerLazySingleton(() => UploadPostImages(sl()));
  sl.registerLazySingleton(() => CreatePostUsecase(sl()));
  sl.registerLazySingleton(() => AddCommentUsecase(sl()));
  sl.registerLazySingleton(() => AddFeedbackUsecase(sl()));
  sl.registerLazySingleton(() => AddUniverstityUsecase(sl()));
  sl.registerLazySingleton(() => AddVoteUsecase(sl()));
  sl.registerLazySingleton(() => UploadVerificationImagesUsecase(sl()));
  sl.registerLazySingleton(() => CreateVarificationRequestUsecase(sl()));
  sl.registerLazySingleton(() => FetchPendingVerificationUsecase(sl()));
  sl.registerLazySingleton(() => UpdateVerificationStatusUsecase(sl()));
  sl.registerLazySingleton(() => FetchPromotionUsecase(sl()));
  sl.registerLazySingleton(() => FetchUniversityUsecase(sl()));
  sl.registerLazySingleton(() => UpdateIssuePostUsecase(sl()));
  sl.registerLazySingleton(() => UpdatePromotionUsecase(sl()));
  sl.registerLazySingleton(() => ChangeRoleRequestUsecase(sl()));
  sl.registerLazySingleton(() => FetchRoleChangeUsecase(sl()));
  sl.registerLazySingleton(() => UpdateUserRoleUsecase(sl()));
  // BLoCs
  sl.registerLazySingleton(() => AuthBloc(
        getUserProfile: sl(),
        uploadUserImage: sl(),
        signUpUser: sl(),
        createUserProfile: sl(),
        signOutUser: sl(),
        signInUser: sl(),
      ));
  sl.registerLazySingleton(() => PostBloc(
        createPost: sl(),
        uploadPostImages: sl(),
        issueBloc: sl(),
      ));

  sl.registerLazySingleton(() => PromotionBloc(
        uploadPostImages: sl(),
        createPromotion: sl(),
      ));

  sl.registerLazySingleton(() => IssueBloc(
        addCommentUsecase: sl(),
        fetchPosts: sl(),
        addFeedbackUsecase: sl(),
        updateIssuePostUsecase: sl(),
      ));

  sl.registerLazySingleton(() => AdminBloc(sl()));
  sl.registerLazySingleton(() => VarificationBloc(
        uploadVerificationImages: sl(),
        createVarificationRequest: sl(),
      ));

  sl.registerLazySingleton(() => VerifyUserBloc(
        fetchPendingVerificationUsecase: sl(),
        updateVerificationStatusUsecase: sl(),
      ));

  sl.registerLazySingleton(() => AdsBloc(
        fetchPromotionUsecase: sl(),
        updatePromotionUsecase: sl(),
      ));

  sl.registerLazySingleton(() => UniversityBloc(
        fetchUniversityUsecase: sl(),
      ));

  sl.registerLazySingleton(() => RoleChangeBloc(
        fetchRoleChangeUsecase: sl(),
        changeRoleRequest: sl(),
        updateUserRoleUsecase: sl(),
      ));
  //Auth Service
  sl.registerLazySingleton(() => AuthService());
}
