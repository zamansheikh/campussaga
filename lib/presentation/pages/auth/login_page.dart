// lib/presentation/pages/auth/login_page.dart

import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/pages/widgets/text_editing_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';

import '../../bloc/auth/auth_state.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log In")),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextEditingField(
                  controller: emailController,
                  labelText: "Email",
                  icon: Icons.email,
                ),
                SizedBox(height: 20),
                TextEditingField(
                  controller: passwordController,
                  labelText: "Password",
                  icon: Icons.lock,
                  isObscure: true,
                ),
                SizedBox(height: 20),
                (state is AuthLoading)
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          BlocProvider.of<AuthBloc>(context).add(
                            SignInEvent(
                              email: emailController.text,
                              password: passwordController.text,
                            ),
                          );
                        },
                        child: Text("Log In"),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/signup');
                  },
                  child: Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
