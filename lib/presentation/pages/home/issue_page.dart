import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/theme/app_theme.dart';
import 'package:campus_saga/core/utils/validators.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/bloc/issue/issue_bloc.dart';
import 'package:campus_saga/presentation/pages/admin/admin_page.dart';
import 'package:campus_saga/core/notifications/notification_sheet.dart';
import 'package:campus_saga/presentation/pages/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class IssuePage extends StatefulWidget {
  const IssuePage({super.key});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  var userState = null;
  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() {
    final state = sl<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      setState(() {
        userState = state.user;
      });
      final String universityId = state.user.universityId
          .split('@')
          .last
          .trim();
      print("Fetching posts for university: $universityId");
      sl<IssueBloc>().add(FetchIssueEvent(universityId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.book_1, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              'Campus Saga',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification, size: 22),
            onPressed: () => showNotificationsSheet(context),
          ),
          const SizedBox(width: 4),
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

          return BlocBuilder<IssueBloc, IssueState>(
            bloc: sl<IssueBloc>(),
            builder: (context, issueState) {
              print("Post state: ${issueState.runtimeType}");
              if (issueState is IssueLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (issueState is IssueFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.warning_2,
                          size: 48,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        issueState.message,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchPosts,
                        icon: const Icon(Iconsax.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (issueState is IssueLoaded && issueState.posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.document_text,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to create a post!',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (issueState is IssueLoaded) {
                return RefreshIndicator(
                  onRefresh: () async => _fetchPosts(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: issueState.posts.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            _SectionHeader(
                              label: 'Latest Issues',
                              icon: Iconsax.flash_1,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PostCard(
                                post: issueState.posts[index],
                                user: authState.user,
                              ),
                            ),
                          ],
                        );
                      }
                      if (index == 2) {
                        return Column(
                          children: [
                            _SectionHeader(
                              label: 'Trending Issues',
                              icon: Iconsax.trend_up,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PostCard(
                                post: issueState.posts[index],
                                user: authState.user,
                              ),
                            ),
                          ],
                        );
                      }
                      if (index == 7) {
                        return Column(
                          children: [
                            _SectionHeader(
                              label: 'Other Issues',
                              icon: Iconsax.document_text_1,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PostCard(
                                post: issueState.posts[index],
                                user: authState.user,
                              ),
                            ),
                          ],
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PostCard(
                          post: issueState.posts[index],
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
      floatingActionButton: (userState != null)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (userState.userType == UserType.admin ||
                    Validators.isDev(userState))
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminPage(user: userState as User),
                        ),
                      );
                    },
                    tooltip: 'Admin Panel',
                    backgroundColor: AppColors.primary,
                    child: const Icon(Iconsax.shield_tick, color: Colors.white),
                  ),
              ],
            )
          : null,
    );
  }
}
// ── Section header widget ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
