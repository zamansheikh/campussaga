import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        title: Text(
          "Campus Saga",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => sl<AuthBloc>().add(SignOutEvent()),
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
            return SingleChildScrollView(
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
                    const SizedBox(height: 24.0),

                    // Achievements and Badges
                    _buildAchievements(user),
                    const SizedBox(height: 24.0),

                    // Student Details (if applicable)
                    if (user.userType == UserType.student)
                      _buildStudentDetails(user),
                  ],
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
        const SizedBox(height: 16.0),
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
        Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(Icons.post_add, user.postCount, "Posts"),
                _buildMetricItem(Icons.comment, user.commentCount, "Comments"),
                _buildMetricItem(
                    Icons.check_circle, user.resolvedIssuesCount, "Resolved"),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                    Icons.thumb_up, user.receivedVotesCount, "Received Votes"),
                _buildMetricItem(
                    Icons.how_to_vote, user.givenVotesCount, "Given Votes"),
                _buildMetricItem(Icons.star, user.streakDays, "Day Streak"),
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
            const SizedBox(height: 16.0),
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
