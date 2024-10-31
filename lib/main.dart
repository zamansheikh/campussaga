// lib/main.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection_container.dart' as di;
import 'package:campus_saga/presentation/pages/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

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
          create: (_) => di.sl<AuthBloc>(),
        ),
        BlocProvider<PostBloc>(
          create: (_) => di.sl<PostBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Campus Saga',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SplashScreen(), // Set SplashScreen as the initial route
      ),
    );
  }
}
