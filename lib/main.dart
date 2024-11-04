// lib/main.dart
import 'package:campus_saga/presentation/pages/auth/login_page.dart';
import 'package:campus_saga/presentation/pages/auth/register_page.dart';
import 'package:campus_saga/presentation/pages/home/home_page.dart';
import 'package:campus_saga/presentation/pages/home/issue_page.dart';
import 'package:campus_saga/presentation/pages/post/create_post_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      ],
      child: MaterialApp(
        title: 'Campus Saga',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: {
          '/login': (context) => LoginPage(),
          '/splash': (context) => SplashScreen(),
          '/signup': (context) => RegisterPage(),
          '/home': (context) => HomePage(),
          '/issue': (context) => IssuePage(),
          '/post': (context) => CreatePostPage(),
        },
        home: SplashScreen(), // Set SplashScreen as the initial route
      ),
    );
  }
}
