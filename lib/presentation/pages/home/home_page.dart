import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/pages/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_state.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Dispatch the logout event
              BlocProvider.of<AuthBloc>(context).add(SignOutEvent());
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // Navigate to the login page or any other appropriate action
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        child: ListView.builder(
          itemCount: 10, // Placeholder count for posts
          itemBuilder: (context, index) {
            return PostCard(postId: 'post_$index'); // Dummy postId
          },
        ),
      ),
    );
  }
}
