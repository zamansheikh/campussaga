import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/bloc/role_manage/role_change_bloc.dart';
import 'package:campus_saga/presentation/pages/profile/update_profile_page.dart';
import 'package:campus_saga/presentation/pages/profile/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  RoleChange _changeRoleEntity() {
    final user = (sl<AuthBloc>().state as AuthAuthenticated).user;
    return RoleChange(
      role: user.userType.toString().split('.').last,
      userName: user.name,
      timestamp: DateTime.now(),
      email: user.email,
      uuid: user.id,
      phoneNumber: user.phoneNumber ?? "Not Available",
      profilePicture: user.profilePictureUrl,
      status: "pending",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        shadowColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        title: Text(
          "User Profile",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications page
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
            final User user = state.user;
            return RefreshIndicator(
              onRefresh: () async {
                sl<AuthBloc>().add(AuthRefreshRequested());
                return Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Header
                      _buildProfileHeader(user),
                      const SizedBox(height: 24.0),

                      // Engagement Metrics
                      _buildEngagementMetrics(user),

                      // Achievements and Badges
                      _buildAchievements(user),

                      // Student Details (if applicable)
                      if (user.userType == UserType.student)
                        _buildStudentDetails(user),

                      //edit profile button
                      const SizedBox(height: 10.0),
                      CustomButton(
                        color: Colors.indigoAccent,
                        text: "Edit Profile",
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      UpdateProfilePage(user: user)));
                        },
                      ),
                      const SizedBox(height: 10.0),
                      CustomButton(
                        color: Colors.green,
                        text: "Terms and Conditions",
                        onPressed: () async {
                          launchURL(
                              "https://github.com/zamansheikh/campus_saga/blob/main/docs/SRS.md");
                        },
                      ),
                      const SizedBox(height: 10.0),
                      CustomButton(
                        color: Colors.blue,
                        text: "About Us",
                        onPressed: () async {
                          launchURL("https://zamansheikh.com");
                        },
                      ),
                      const SizedBox(height: 10.0),
                      CustomButton(
                        color: Colors.red,
                        text: "Logout",
                        onPressed: () {
                          BlocProvider.of<AuthBloc>(context)
                              .add(SignOutEvent());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.profilePictureUrl),
            ),
            if (user.isVerified)
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
          ],
        ),
        if (!user.isVerified)
          Column(
            children: [
              const SizedBox(height: 12),
              CustomButton(
                  size: const Size(140, 40),
                  color: Colors.blue,
                  text: "Verify Account",
                  onPressed: () {
                    //materialPageRoute
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VerificationPage(
                                  user: user,
                                )));
                  }),
            ],
          ),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          user.email,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8.0),
        InkWell(
          onLongPress: () {
            copyToClipboard(user.id, "User ID copied to clipboard");
            sl<RoleChangeBloc>().add(ChangeRoleEvent(_changeRoleEntity()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getUserTypeColor(user.userType),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getUserTypeText(user.userType),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Engagement",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    _buildMetricItem(Icons.post_add, user.postCount, "Posts"),
                    const SizedBox(height: 16.0),
                    _buildMetricItem(
                        Icons.comment, user.commentCount, "Comments"),
                  ],
                ),
                Column(
                  children: [
                    _buildMetricItem(Icons.check_circle,
                        user.resolvedIssuesCount, "Resolved"),
                    const SizedBox(height: 16.0),
                    _buildMetricItem(Icons.thumb_up, user.receivedVotesCount,
                        "Received Votes"),
                  ],
                ),
                Column(
                  children: [
                    _buildMetricItem(
                        Icons.how_to_vote, user.givenVotesCount, "Given Votes"),
                    const SizedBox(height: 16.0),
                    _buildMetricItem(Icons.star, user.streakDays, "Day Streak"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Achievements",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _buildBadge(user.currentBadge),
              ],
            ),
            // const SizedBox(height: 16.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: user.achievements.map((achievement) {
                return Chip(
                  avatar: const Icon(Icons.emoji_events, size: 18),
                  label: Text(_getAchievementText(achievement)),
                  backgroundColor: Colors.amber[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDetails(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Student Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            if (user.studentId != null)
              _buildDetailRow("Student ID", user.studentId!),
            if (user.department != null)
              _buildDetailRow(
                  "Department", _getDepartmentText(user.department!)),
            if (user.batch != null)
              _buildDetailRow("Batch", user.batch.toString()),
            if (user.cgpa != null)
              _buildDetailRow("CGPA", user.cgpa.toString()),
            if (user.currentSemester != null)
              _buildDetailRow("Semester", user.currentSemester!),
            if (user.phoneNumber != null)
              _buildDetailRow("Phone", user.phoneNumber!),
            if (user.clubNames?.isNotEmpty ?? false)
              _buildDetailRow("Clubs", user.clubNames!.join(", ")),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, int value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(UserBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getBadgeColors(badge),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getBadgeText(badge),
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper methods...
  String _getBadgeText(UserBadge badge) {
    return badge.toString().split('.').last.toUpperCase();
  }

  List<Color> _getBadgeColors(UserBadge badge) {
    switch (badge) {
      case UserBadge.newbie:
        return [Colors.grey, Colors.grey.shade600];
      case UserBadge.active:
        return [Colors.green, Colors.green.shade700];
      case UserBadge.expert:
        return [Colors.blue, Colors.blue.shade700];
      case UserBadge.hero:
        return [Colors.purple, Colors.purple.shade700];
      case UserBadge.legend:
        return [Colors.orange, Colors.red];
    }
  }

  String _getAchievementText(AchievementType achievement) {
    return achievement
        .toString()
        .split('.')
        .last
        .split(RegExp(r'(?=[A-Z])'))
        .join(' ');
  }

  String _getDepartmentText(Department department) {
    return department.toString().split('.').last.toUpperCase();
  }

  // Helper method to copy text to clipboard
  void copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
      case UserType.ambassador:
        return Colors.purple;
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
      case UserType.ambassador:
        return "Ambassador";
    }
  }
}

class CustomButton extends StatelessWidget {
  final Color? color;
  final Size? size;
  final String text;
  final Function()? onPressed;

  const CustomButton({
    Key? key,
    this.color,
    required this.text,
    this.onPressed,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size?.width ?? double.infinity,
      height: size?.height ?? 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              color ?? Colors.red, // Use provided color or default to red
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Border radius
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text, // Use provided text or default to "Button"
          style: const TextStyle(color: Colors.white), // Text color
        ),
      ),
    );
  }
}
