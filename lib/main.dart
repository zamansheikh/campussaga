// lib/main.dart
import 'package:campus_saga/presentation/bloc/admin/admin_bloc.dart';
import 'package:campus_saga/presentation/bloc/ads/ads_bloc.dart';
import 'package:campus_saga/presentation/bloc/promotion/promotion_bloc.dart';
import 'package:campus_saga/presentation/bloc/role_manage/role_change_bloc.dart';
import 'package:campus_saga/presentation/bloc/university/university_bloc.dart';
import 'package:campus_saga/presentation/bloc/varify/varification_bloc.dart';
import 'package:campus_saga/presentation/bloc/verify_user/verify_user_bloc.dart';
import 'package:campus_saga/presentation/pages/admin/add_university_page.dart';
import 'package:campus_saga/presentation/pages/admin/user_verify_page.dart';
import 'package:campus_saga/presentation/pages/auth/login_page.dart';
import 'package:campus_saga/presentation/pages/auth/register_page.dart';
import 'package:campus_saga/presentation/pages/home/home_page.dart';
import 'package:campus_saga/presentation/pages/home/issue_page.dart';
import 'package:campus_saga/presentation/pages/post/create_post_page.dart';
import 'package:campus_saga/presentation/pages/ranking/ranking_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/injection_container.dart' as di;
import 'package:campus_saga/presentation/pages/splash/splash_screen.dart';
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        BlocProvider<PostBloc>(
          create: (_) => sl<PostBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<PromotionBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<AdminBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<VarificationBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<VerifyUserBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<AdsBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<UniversityBloc>(),
        ),
        BlocProvider(
          create: (_) => sl<RoleChangeBloc>(),
        )
      ],
      child: MaterialApp(
        title: 'Campus Saga',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          primarySwatch: Colors.blue,
        ),
        routes: {
          '/login': (context) => LoginPage(),
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
      ),
    );
  }
}
