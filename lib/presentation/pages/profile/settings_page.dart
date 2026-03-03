import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/theme/app_theme.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/pages/profile/update_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121418)
          : const Color(0xFFF6F7FA),
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // ── Account ───────────────────────────────────────────────
              _SectionHeader('Account'),
              _SettingsTile(
                icon: Iconsax.user_edit,
                iconColor: AppColors.primary,
                title: 'Edit Profile',
                subtitle: 'Update name, photo and details',
                onTap: user != null
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateProfilePage(user: user),
                        ),
                      )
                    : null,
              ),
              _SettingsTile(
                icon: Iconsax.notification,
                iconColor: const Color(0xFF7C4DFF),
                title: 'Notifications',
                subtitle: 'Manage push notification preferences',
                onTap: () => _showComingSoon(context, 'Notification Settings'),
              ),
              _SettingsTile(
                icon: Iconsax.language_square,
                iconColor: const Color(0xFF00BCD4),
                title: 'Language',
                subtitle: 'English (default)',
                trailing: _ComingSoonBadge(),
                onTap: () => _showComingSoon(context, 'Language Settings'),
              ),
              _SettingsTile(
                icon: Iconsax.moon,
                iconColor: const Color(0xFF9E9E9E),
                title: 'Appearance',
                subtitle: isDark ? 'Dark mode • system' : 'Light mode • system',
                trailing: _ComingSoonBadge(),
                onTap: () => _showComingSoon(context, 'Appearance Settings'),
              ),

              const SizedBox(height: 8),

              // ── Information ───────────────────────────────────────────
              _SectionHeader('Information'),
              _SettingsTile(
                icon: Iconsax.shield_tick,
                iconColor: const Color(0xFF4CAF50),
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => launchURL(
                  'https://github.com/zamansheikh/campus_saga/blob/main/docs/SRS.md',
                ),
              ),
              _SettingsTile(
                icon: Iconsax.document_text,
                iconColor: const Color(0xFFFF9800),
                title: 'Terms & Conditions',
                subtitle: 'Rules and usage policy',
                onTap: () => launchURL(
                  'https://github.com/zamansheikh/campus_saga/blob/main/docs/SRS.md',
                ),
              ),
              _SettingsTile(
                icon: Iconsax.info_circle,
                iconColor: const Color(0xFF2196F3),
                title: 'About Campus Saga',
                subtitle: 'Version info and acknowledgements',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Iconsax.star,
                iconColor: const Color(0xFFFFB300),
                title: 'Rate Us',
                subtitle: 'Love the app? Leave a review!',
                onTap: () => launchURL('https://zamansheikh.com'),
              ),
              _SettingsTile(
                icon: Iconsax.message_question,
                iconColor: const Color(0xFF009688),
                title: 'Support & Feedback',
                subtitle: 'Report a bug or suggest a feature',
                onTap: () => launchURL('https://zamansheikh.com'),
              ),

              const SizedBox(height: 8),

              // ── Danger Zone ───────────────────────────────────────────
              _SectionHeader('Danger Zone'),
              _SettingsTile(
                icon: Iconsax.logout,
                iconColor: Colors.orange,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                isDestructive: false,
                onTap: () => _confirmLogout(context),
              ),
              _SettingsTile(
                icon: Iconsax.trash,
                iconColor: Colors.red,
                title: 'Delete Account',
                subtitle: 'Permanently remove all your data',
                isDestructive: true,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.clock, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              '$feature coming soon!',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.book_1, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Campus Saga',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutRow('Version', '1.0.0'),
            _AboutRow('Developer', 'Programmers Nexus'),
            _AboutRow('Platform', 'Flutter · Firebase'),
            _AboutRow('Target', 'Bangladeshi Students'),
            const SizedBox(height: 10),
            Text(
              'Campus Saga empowers students to raise campus issues, track resolutions in real time and celebrate their university community.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              launchURL('https://zamansheikh.com');
            },
            child: Text(
              'Visit Website',
              style: GoogleFonts.poppins(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              sl<AuthBloc>().add(SignOutEvent());
            },
            child: Text('Logout', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your posts, comments and data will be deleted forever.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account deletion coming soon.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Text('Delete', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isDestructive ? Colors.red : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDestructive
              ? Colors.red.withAlpha(60)
              : Theme.of(context).colorScheme.outline.withAlpha(35),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(isDestructive ? 30 : 22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: effectiveColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: isDestructive
                  ? Colors.red.withAlpha(150)
                  : const Color(0xFF9CA3AF),
            ),
        onTap: onTap,
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Soon',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
