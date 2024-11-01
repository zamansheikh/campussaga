import 'package:campus_saga/core/constants/dummypost.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/bloc/post/post_bloc.dart';
import 'package:campus_saga/presentation/bloc/post/post_event.dart';
import 'package:campus_saga/presentation/bloc/post/post_state.dart';
import 'package:campus_saga/presentation/pages/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IssuePage extends StatefulWidget {
  const IssuePage({super.key});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  @override
  void initState() {
    Future.delayed(
        Duration(
          seconds: 2,
        ), () {
      BlocProvider.of<PostBloc>(context).add(FetchPosts(
        (sl<AuthBloc>().state as AuthAuthenticated)
            .user
            .universityId
            .split('@')
            .last
            .trim(),
      ));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Latest Issues",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Dispatch the logout event
              BlocProvider.of<AuthBloc>(context).add(SignOutEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return BlocBuilder<PostBloc, PostState>(
              builder: (context, poststate) {
                if (poststate is PostLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (poststate is PostsFetched) {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: poststate
                              .posts.length, // Placeholder count for posts
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: PostCard(
                                user: state.user,
                                post: poststate.posts[index],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text("No Posts Found"),
                  );
                }
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create issue page
          _addDummyIssue();
        },
        child: const Icon(Icons.add),
        tooltip: "Add New Issue",
      ),
    );
  }

  void _addDummyIssue() {
    // Dummy post data
    if (BlocProvider.of<AuthBloc>(context).state is AuthAuthenticated) {
      final user =
          BlocProvider.of<AuthBloc>(context).state as AuthAuthenticated;
      BlocProvider.of<PostBloc>(context).add(
        PostCreated(
          dummyPostGenerate(user.user), // Replace with actual post data
        ),
      );
    }
  }
}
