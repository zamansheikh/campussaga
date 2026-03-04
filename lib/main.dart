// lib/main.dart
import 'package:campussaga/core/notifications/notification_service.dart';
import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/core/theme/theme_cubit.dart';
import 'package:campussaga/presentation/bloc/admin/admin_bloc.dart';
import 'package:campussaga/presentation/bloc/ads/ads_bloc.dart';
import 'package:campussaga/presentation/bloc/promotion/promotion_bloc.dart';
import 'package:campussaga/presentation/bloc/role_manage/role_change_bloc.dart';
import 'package:campussaga/presentation/bloc/university/university_bloc.dart';
import 'package:campussaga/presentation/bloc/varify/varification_bloc.dart';
import 'package:campussaga/presentation/bloc/verify_user/verify_user_bloc.dart';
import 'package:campussaga/presentation/pages/admin/add_university_page.dart';
import 'package:campussaga/presentation/pages/admin/user_verify_page.dart';
import 'package:campussaga/presentation/pages/auth/onboarding_page.dart';
import 'package:campussaga/presentation/pages/auth/login_page.dart';
import 'package:campussaga/presentation/pages/auth/register_page.dart';
import 'package:campussaga/presentation/pages/home/home_page.dart';
import 'package:campussaga/presentation/pages/home/issue_page.dart';
import 'package:campussaga/presentation/pages/post/create_post_page.dart';
import 'package:campussaga/presentation/pages/ranking/ranking_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection_container.dart' as di;
import 'package:campussaga/presentation/pages/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/injection_container.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/post/post_bloc.dart';

// import 'presentation/bloc/auth/auth_bloc.dart';
// import 'presentation/bloc/post/post_bloc.dart';
// import 'presentation/pages/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await di.init(); // Initialize dependency injection
  await NotificationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<PostBloc>(create: (_) => sl<PostBloc>()),
        BlocProvider(create: (_) => sl<PromotionBloc>()),
        BlocProvider(create: (_) => sl<AdminBloc>()),
        BlocProvider(create: (_) => sl<VarificationBloc>()),
        BlocProvider(create: (_) => sl<VerifyUserBloc>()),
        BlocProvider(create: (_) => sl<AdsBloc>()),
        BlocProvider(create: (_) => sl<UniversityBloc>()),
        BlocProvider(create: (_) => sl<RoleChangeBloc>()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Campus Saga',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routes: {
              '/login': (context) => const LoginPage(),
              '/onboarding': (context) => const OnboardingPage(),
              '/splash': (context) => SplashScreen(),
              '/signup': (context) => RegisterPage(),
              '/home': (context) => HomePage(),
              '/issue': (context) => IssuePage(),
              '/post': (context) => CreatePostPage(),
              '/ranking': (context) => RankingPage(),
              '/addUniversity': (context) => AddUniversityPage(),
              '/userVerification': (context) => UserVerifyPage(),
            },
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}
