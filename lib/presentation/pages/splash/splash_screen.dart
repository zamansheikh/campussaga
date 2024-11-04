import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/services/auth_service.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthBloc _authBloc = sl<AuthBloc>();
  final AuthService _authState = sl<AuthService>();

  @override
  void initState() {
    super.initState();
    final uid = _authState.currentUser?.uid;

    if (uid != null) {
      _authBloc.add(AuthRequested(uid));
    } else {
      _authBloc.add(SignOutEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        bloc: _authBloc,
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } else if (state is AuthUnauthenticated || state is AuthFailure) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
