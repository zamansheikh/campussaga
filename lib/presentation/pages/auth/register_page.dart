// lib/pages/auth/register_page.dart

import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/pages/widgets/text_editing_field.dart';
import 'package:campus_saga/presentation/pages/widgets/university_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final List<String> universities = [
    'University A',
    'University B',
    'University C'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      // Implement image picker here
                    },
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.add_a_photo),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextEditingField(
                    controller: userNameController,
                    labelText: "User Name",
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),
                  UniversitySearchField(
                    controller: universityController,
                    universityList: universities,
                  ),
                  SizedBox(height: 20),
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
                            BlocProvider.of<AuthBloc>(context).add(SignUpEvent(
                              username: userNameController.text,
                              email: emailController.text,
                              password: passwordController.text,
                              university: universityController.text,
                            ));
                          },
                          child: Text("Sign Up"),
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
