import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/notifications/notification_sheet.dart';
import 'package:campus_saga/core/theme/app_theme.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        centerTitle: true,
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
              child: const Icon(Iconsax.user, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification),
            onPressed: () => showNotificationsSheet(context),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header
                    _buildProfileHeader(user),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Engagement Metrics
                          _buildEngagementMetrics(user),
                          const SizedBox(height: 16),
                          // Achievements
                          _buildAchievements(user),
                          const SizedBox(height: 16),
                          // Student Details
                          if (user.userType == UserType.student) ...[
                            _buildStudentDetails(user),
                            const SizedBox(height: 16),
                          ],
                          // Action buttons
                          _ActionButton(
                            icon: Iconsax.edit_2,
                            text: 'Edit Profile',
                            color: AppColors.primary,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UpdateProfilePage(user: user),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ActionButton(
                            icon: Iconsax.document_text,
                            text: 'Terms and Conditions',
                            color: const Color(0xFF4CAF50),
                            onPressed: () => launchURL(
                              "https://github.com/zamansheikh/campus_saga/blob/main/docs/SRS.md",
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ActionButton(
                            icon: Iconsax.info_circle,
                            text: 'About Us',
                            color: const Color(0xFF00BCD4),
                            onPressed: () =>
                                launchURL("https://zamansheikh.com"),
                          ),
                          const SizedBox(height: 10),
                          _ActionButton(
                            icon: Iconsax.logout,
                            text: 'Logout',
                            color: Colors.red,
                            onPressed: () => BlocProvider.of<AuthBloc>(
                              context,
                            ).add(SignOutEvent()),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.darkGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          InkWell(
            onLongPress: () {
              copyToClipboard(user.id, "User ID copied to clipboard");
              sl<RoleChangeBloc>().add(ChangeRoleEvent(_changeRoleEntity()));
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(160),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundImage: NetworkImage(user.profilePictureUrl),
                  ),
                ),
                if (user.isVerified)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.verify5,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withAlpha(190),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _getUserTypeColor(user.userType).withAlpha(200),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(80), width: 1),
            ),
            child: Text(
              _getUserTypeText(user.userType),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!user.isVerified) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VerificationPage(user: user)),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Iconsax.shield_tick, size: 16),
              label: Text(
                'Verify Account',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  Iconsax.document_text,
                  user.postCount,
                  'Posts',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  Iconsax.tick_circle,
                  user.resolvedIssuesCount,
                  'Resolved',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  Iconsax.message_text,
                  user.commentCount,
                  'Comments',
                  color: const Color(0xFF00BCD4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  Iconsax.like_1,
                  user.givenVotesCount,
                  'Given',
                  color: const Color(0xFF7C4DFF),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  Iconsax.heart,
                  user.receivedVotesCount,
                  'Received',
                  color: Colors.pink,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  Iconsax.star_1,
                  user.streakDays,
                  'Streak',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildBadge(user.currentBadge),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: user.achievements.map((achievement) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.award,
                      size: 13,
                      color: Color(0xFFFFB300),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getAchievementText(achievement),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDetails(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (user.studentId != null)
            _buildDetailRow(Iconsax.card, 'Student ID', user.studentId!),
          if (user.department != null)
            _buildDetailRow(
              Iconsax.building,
              'Department',
              _getDepartmentText(user.department!),
            ),
          if (user.batch != null)
            _buildDetailRow(Iconsax.calendar, 'Batch', user.batch.toString()),
          if (user.cgpa != null)
            _buildDetailRow(Iconsax.chart_2, 'CGPA', user.cgpa.toString()),
          if (user.currentSemester != null)
            _buildDetailRow(Iconsax.book_1, 'Semester', user.currentSemester!),
          if (user.phoneNumber != null)
            _buildDetailRow(Iconsax.call, 'Phone', user.phoneNumber!),
          if (user.clubNames?.isNotEmpty ?? false)
            _buildDetailRow(
              Iconsax.people,
              'Clubs',
              user.clubNames!.join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    int value,
    String label, {
    Color color = AppColors.primary,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF9CA3AF),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(UserBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getBadgeColors(badge)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getBadgeText(badge),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

// ── Action button helper ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDestructive = color == Colors.red;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isDestructive
          ? OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(icon, size: 18),
              label: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(icon, size: 18),
              label: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

// ── CustomButton (kept for compatibility with other pages) ────────────────────

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
    return SizedBox(
      width: size?.width ?? double.infinity,
      height: size?.height ?? 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
