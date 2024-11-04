import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/domain/entities/post.dart';
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
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() {
    final state = sl<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      final String universityId =
          state.user.universityId.split('@').last.trim();
      print("Fetching posts for university: $universityId");
      sl<PostBloc>().add(FetchPosts(universityId));
    }
  }

  List<Post> posts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Latest Issues"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => sl<AuthBloc>().add(SignOutEvent()),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        bloc: sl<AuthBloc>(),
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<PostBloc, PostState>(
            bloc: sl<PostBloc>(),
            builder: (context, postState) {
              print("Post state: $postState");
              if (postState is PostLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (postState is PostFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(postState.message),
                      ElevatedButton(
                        onPressed: _fetchPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (postState is PostsFetched && postState.posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.post_add, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No posts yet",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        "Be the first to create a post!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (postState is PostsFetched) {
                return RefreshIndicator(
                  onRefresh: () async => _fetchPosts(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: postState.posts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PostCard(
                          post: postState.posts[index],
                          user: authState.user,
                        ),
                      );
                    },
                  ),
                );
              }

              return const Center(child: Text("Something went wrong"));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
