

import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final User user = state.user;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture with Verification Badge
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(user.profilePictureUrl),
                      ),
                      if (user.isVerified) // Verification badge
                        const Icon(
                          Icons.check_circle,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // User Name
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4.0),

                  // User Email
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 16.0),

                  // UserType Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUserTypeColor(user.userType),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getUserTypeText(user.userType),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // University ID
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "University Name",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            user.universityId,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Helper methods for UserType display
  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.student:
        return Colors.blue;
      case UserType.university:
        return Colors.green;
      case UserType.admin:
        return Colors.orange;
    }
  }

  String _getUserTypeText(UserType userType) {
    switch (userType) {
      case UserType.student:
        return "Student";
      case UserType.university:
        return "University";
      case UserType.admin:
        return "Admin";
    }
  }
}
