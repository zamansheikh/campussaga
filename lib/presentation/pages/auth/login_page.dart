// lib/presentation/pages/auth/login_page.dart

import 'package:campus_saga/core/constants/App_colors.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/pages/widgets/text_editing_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/core/utils/validators.dart';

import '../../bloc/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Light gray background
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor, // Green for AppBar
        centerTitle: true,
        title: Text(
          "Log In",
          style:
              TextStyle(color: AppColors.buttonTextColor), // White AppBar title
        ),
        iconTheme:
            IconThemeData(color: AppColors.buttonTextColor), // White icons
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Logged In Successfully")),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthUnauthenticated) {
            BlocProvider.of<AuthBloc>(context).add(SignOutEvent());
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextEditingField(
                    controller: emailController,
                    labelText: "Email",
                    icon: Icons.email,
                    backgroundColor:
                        AppColors.inputFieldFillColor, // Soft gray background
                    hintTextColor:
                        AppColors.hintTextColor, // Light gray for hint text
                    validator: (value) {
                      if (!Validators.isValidEmail(value ?? '')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextEditingField(
                    controller: passwordController,
                    labelText: "Password",
                    icon: Icons.lock,
                    isObscure: true,
                    fillColor:
                        AppColors.inputFieldFillColor, // Soft gray background
                    hintTextColor:
                        AppColors.hintTextColor, // Light gray for hint text
                    validator: (value) {
                      if (!Validators.isValidPassword(value ?? '')) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  if (state is AuthLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.buttonColor, // Blue button color
                        foregroundColor:
                            AppColors.buttonTextColor, // White text color
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          BlocProvider.of<AuthBloc>(context).add(
                            SignInEvent(
                              email: emailController.text,
                              password: passwordController.text,
                            ),
                          );
                        }
                      },
                      child: Text("Log In"),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/signup');
                    },
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(
                          color: AppColors.primaryColor), // Green text
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
