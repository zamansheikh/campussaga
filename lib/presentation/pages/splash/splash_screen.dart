// lib/presentation/pages/splash/splash_screen.dart

import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/main.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = sl<AuthService>();

  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuthStatus();
  }

  Future<void> _navigateBasedOnAuthStatus() async {
    final currentUser = await _authService.isUserLoggedIn();
    print('isLoggedIn: ${currentUser?.email}');
    if (currentUser != null) {
      
      sl<AuthBloc>().add(AuthRequested(currentUser.uid));
      print("AuthState: ${sl<AuthBloc>().state}");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
