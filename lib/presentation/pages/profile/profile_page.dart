import 'package:campussaga/core/injection_container.dart';
import 'package:campussaga/core/notifications/notification_panel.dart';
import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/core/utils/utils.dart';
import 'package:campussaga/domain/entities/role_change.dart';
import 'package:campussaga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_event.dart';
import 'package:campussaga/presentation/bloc/auth/auth_state.dart';
import 'package:campussaga/presentation/bloc/role_manage/role_change_bloc.dart';
import 'package:campussaga/presentation/pages/profile/settings_page.dart';
import 'package:campussaga/presentation/pages/profile/update_profile_page.dart';
import 'package:campussaga/presentation/pages/profile/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:campussaga/domain/entities/user.dart';
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
      phoneNumber: user.phoneNumber ?? 'Not Available',
      profilePicture: user.profilePictureUrl,
      status: 'pending',
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      endDrawer: const NotificationPanel(),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                sl<AuthBloc>().add(AuthRefreshRequested());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(user),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: Column(
                        children: [
                          if (user.userType == UserType.student) ...[
                            _buildSectionCard(
                              icon: Iconsax.profile_2user,
                              title: 'Student Details',
                              child: _buildStudentDetails(user),
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildSectionCard(
                            icon: Iconsax.award,
                            title: 'Achievements',
                            trailing: _buildBadge(user.currentBadge),
                            child: user.achievements.isEmpty
                                ? _emptyAchievements()
                                : _buildAchievements(user),
                          ),
                          const SizedBox(height: 20),
                          _buildSettingsTile(
                            icon: Iconsax.edit_2,
                            title: 'Edit Profile',
                            subtitle: 'Update your name, photo & details',
                            iconBg: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UpdateProfilePage(user: user),
                              ),
                            ),
                          ),
                          _buildSettingsTile(
                            icon: Iconsax.setting_2,
                            title: 'Settings',
                            subtitle: 'Notifications, privacy, language & more',
                            iconBg: const Color(0xFF607D8B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            ),
                          ),
                          _buildSettingsTile(
                            icon: Iconsax.document_text,
                            title: 'Terms & Conditions',
                            subtitle: 'Read our usage policy',
                            iconBg: const Color(0xFF4CAF50),
                            onTap: () => launchURL(
                              'https://zamansheikh.github.io/campussaga/',
                            ),
                          ),
                          _buildSettingsTile(
                            icon: Iconsax.info_circle,
                            title: 'About Us',
                            subtitle: 'Learn more about Campus Saga',
                            iconBg: const Color(0xFF00BCD4),
                            onTap: () => launchURL(
                              'https://zamansheikh.github.io/campussaga/',
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSettingsTile(
                            icon: Iconsax.logout,
                            title: 'Logout',
                            subtitle: 'Sign out of your account',
                            iconBg: Colors.red,
                            isDestructive: true,
                            onTap: () => BlocProvider.of<AuthBloc>(
                              context,
                            ).add(SignOutEvent()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(User user) {
    final typeColor = _getUserTypeColor(user.userType);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.darkGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onLongPress: () {
              _copyToClipboard(user.id, 'User ID copied to clipboard');
              sl<RoleChangeBloc>().add(ChangeRoleEvent(_changeRoleEntity()));
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(170),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.profilePictureUrl),
                  ),
                ),
                if (user.isVerified)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.verify5,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            user.email,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withAlpha(190),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: typeColor.withAlpha(200),
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
            const SizedBox(height: 10),
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
              icon: const Icon(Iconsax.shield_tick, size: 15),
              label: Text(
                'Verify Account',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(40), width: 1),
            ),
            child: Row(
              children: [
                _statItem(user.postCount, 'Posts'),
                _divider(),
                _statItem(user.resolvedIssuesCount, 'Resolved'),
                _divider(),
                _statItem(user.streakDays, 'Day Streak'),
                _divider(),
                _statItem(user.receivedVotesCount, 'Votes'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statItem(int value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withAlpha(180),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 32, color: Colors.white.withAlpha(50));
  }

  // ── Section card ─────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Student details ───────────────────────────────────────────────────────────

  Widget _buildStudentDetails(User user) {
    final rows = <Widget>[];
    if (user.studentId != null)
      rows.add(_detailRow(Iconsax.card, 'Student ID', user.studentId!));
    if (user.department != null)
      rows.add(
        _detailRow(
          Iconsax.building,
          'Department',
          _getDepartmentText(user.department!),
        ),
      );
    if (user.batch != null)
      rows.add(_detailRow(Iconsax.calendar, 'Batch', user.batch.toString()));
    if (user.cgpa != null)
      rows.add(_detailRow(Iconsax.chart_2, 'CGPA', user.cgpa.toString()));
    if (user.currentSemester != null)
      rows.add(_detailRow(Iconsax.book_1, 'Semester', user.currentSemester!));
    if (user.phoneNumber != null)
      rows.add(_detailRow(Iconsax.call, 'Phone', user.phoneNumber!));
    if (user.clubNames?.isNotEmpty ?? false)
      rows.add(_detailRow(Iconsax.people, 'Clubs', user.clubNames!.join(', ')));

    if (rows.isEmpty) {
      return Text(
        'No student details added yet. Tap Edit Profile to fill in.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF9CA3AF),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
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

  // ── Achievements ────────────────────────────────────────────────────────────

  Widget _buildAchievements(User user) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user.achievements.map((achievement) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(40),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.award, size: 13, color: Color(0xFFFFB300)),
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
    );
  }

  Widget _emptyAchievements() {
    return Row(
      children: [
        const Icon(Iconsax.medal_star, size: 18, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          'No achievements yet. Keep engaging!',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(UserBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getBadgeColors(badge)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getBadgeText(badge),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ── Settings tile ────────────────────────────────────────────────────────────

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2024) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withAlpha(60)
                : Theme.of(context).colorScheme.outline.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg.withAlpha(isDestructive ? 30 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconBg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: isDestructive
                  ? Colors.red.withAlpha(150)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _getBadgeText(UserBadge badge) =>
      badge.toString().split('.').last.toUpperCase();

  List<Color> _getBadgeColors(UserBadge badge) {
    switch (badge) {
      case UserBadge.newbie:
        return [const Color(0xFF9E9E9E), const Color(0xFF616161)];
      case UserBadge.active:
        return [const Color(0xFF43A047), const Color(0xFF1B5E20)];
      case UserBadge.expert:
        return AppColors.primaryGradient;
      case UserBadge.hero:
        return [const Color(0xFF7C4DFF), const Color(0xFF3D5AFE)];
      case UserBadge.legend:
        return [const Color(0xFFFF6F00), const Color(0xFFE53935)];
    }
  }

  String _getAchievementText(AchievementType achievement) => achievement
      .toString()
      .split('.')
      .last
      .split(RegExp(r'(?=[A-Z])'))
      .join(' ');

  String _getDepartmentText(Department department) =>
      department.toString().split('.').last.toUpperCase();

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.student:
        return AppColors.primary;
      case UserType.university:
        return const Color(0xFF4CAF50);
      case UserType.admin:
        return Colors.orange;
      case UserType.ambassador:
        return const Color(0xFF7C4DFF);
    }
  }

  String _getUserTypeText(UserType userType) {
    switch (userType) {
      case UserType.student:
        return 'Student';
      case UserType.university:
        return 'University';
      case UserType.admin:
        return 'Admin';
      case UserType.ambassador:
        return 'Ambassador';
    }
  }
}

// ── CustomButton (kept for compatibility with other pages) ─────────────────────

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
