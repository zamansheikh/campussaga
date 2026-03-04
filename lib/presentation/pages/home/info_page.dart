import 'package:campussaga/core/injection_container.dart';
import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/domain/entities/university.dart';
import 'package:campussaga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_state.dart';
import 'package:campussaga/presentation/bloc/university/university_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  void initState() {
    super.initState();
    final state = sl<UniversityBloc>().state;
    if (state is! UniversityLoaded) {
      sl<UniversityBloc>().add(const FetchUniversitiesEvent());
    }
  }

  University? _resolveUniversity(List<University> unis, String universityId) {
    final normalId = universityId.split('@').last.trim().toUpperCase();
    try {
      return unis.firstWhere((u) => u.id.toUpperCase() == normalId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.info_circle,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Campus Info',
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
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        bloc: sl<AuthBloc>(),
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;

          return BlocBuilder<UniversityBloc, UniversityState>(
            bloc: sl<UniversityBloc>(),
            builder: (context, uniState) {
              University? myUniversity;
              if (uniState is UniversityLoaded && user != null) {
                myUniversity = _resolveUniversity(
                  uniState.universities,
                  user.universityId,
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  sl<UniversityBloc>().add(const FetchUniversitiesEvent());
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    // ── My University Card ─────────────────────────
                    _sectionHeader('My University', Iconsax.building_3),
                    if (uniState is UniversityLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (myUniversity != null)
                      _UniversityCard(uni: myUniversity, isDark: isDark)
                    else
                      _EmptyCard(
                        icon: Iconsax.building,
                        message: user == null
                            ? 'Not logged in'
                            : 'University info not available',
                        isDark: isDark,
                      ),

                    const SizedBox(height: 24),

                    // ── Helpline Section ───────────────────────────
                    _sectionHeader('Emergency Helplines', Iconsax.call),
                    _HelplineCard(
                      isDark: isDark,
                      universityName: myUniversity?.name,
                    ),

                    const SizedBox(height: 24),

                    // ── Library Section ────────────────────────────
                    _sectionHeader('Library', Iconsax.book_1),
                    _LibraryCard(
                      isDark: isDark,
                      universityName: myUniversity?.name,
                      onVisitWeb: () => _launchUrl(
                        'https://zamansheikh.github.io/campus_saga/',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Clubs & Organizations ──────────────────────
                    _sectionHeader('Clubs & Organizations', Iconsax.people),
                    _ClubsGrid(isDark: isDark),

                    const SizedBox(height: 24),

                    // ── App Info ───────────────────────────────────
                    _sectionHeader('About Campus Saga', Iconsax.info_circle),
                    _AppInfoCard(
                      isDark: isDark,
                      onPrivacyTap: () => _launchUrl(
                        'https://zamansheikh.github.io/campus_saga/privacy_policy.html',
                      ),
                      onWebsiteTap: () => _launchUrl(
                        'https://zamansheikh.github.io/campus_saga/',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── University Card ──────────────────────────────────────────────────────────
class _UniversityCard extends StatelessWidget {
  final University uni;
  final bool isDark;

  const _UniversityCard({required this.uni, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: uni.logoUrl.isNotEmpty
                    ? Image.network(
                        uni.logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Iconsax.building, color: Colors.white),
                      )
                    : Center(
                        child: Text(
                          uni.name.isNotEmpty ? uni.name[0] : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uni.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            uni.location,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            uni.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: 'Students',
                value: uni.studentCount > 0
                    ? '${(uni.studentCount / 1000).toStringAsFixed(1)}k'
                    : 'N/A',
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Programs',
                value: uni.programsOffered > 0
                    ? '${uni.programsOffered}'
                    : 'N/A',
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Est.',
                value: uni.establishmentYear > 0
                    ? '${uni.establishmentYear}'
                    : 'N/A',
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Type',
                value: uni.isPublic ? 'Public' : 'Private',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Helpline Card ────────────────────────────────────────────────────────────
class _HelplineCard extends StatelessWidget {
  final bool isDark;
  final String? universityName;
  const _HelplineCard({required this.isDark, this.universityName});

  @override
  Widget build(BuildContext context) {
    final lines = [
      _HelplineEntry(
        icon: Iconsax.shield_tick,
        iconBg: const Color(0xFFE53935),
        label: 'Campus Security',
        number: '+880 1XXX-XXXXXX',
        note: '24/7 emergency',
      ),
      _HelplineEntry(
        icon: Iconsax.heart,
        iconBg: const Color(0xFFE91E63),
        label: 'Medical Center',
        number: '+880 1XXX-XXXXXX',
        note: 'On-campus clinic',
      ),
      _HelplineEntry(
        icon: Iconsax.teacher,
        iconBg: const Color(0xFF1976D2),
        label: 'Student Affairs',
        number: '+880 1XXX-XXXXXX',
        note: 'Weekdays 9am–5pm',
      ),
      _HelplineEntry(
        icon: Iconsax.message_question,
        iconBg: const Color(0xFF00897B),
        label: 'Counseling Services',
        number: '+880 1XXX-XXXXXX',
        note: 'Mental health support',
      ),
      _HelplineEntry(
        icon: Iconsax.call,
        iconBg: const Color(0xFFFF6F00),
        label: 'National Emergency',
        number: '999',
        note: 'Police / Fire / Ambulance',
      ),
    ];

    return _InfoCard(
      isDark: isDark,
      child: Column(
        children: lines
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: e.iconBg.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(e.icon, color: e.iconBg, size: 20),
                  ),
                  title: Text(
                    e.label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    e.note,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  trailing: Text(
                    e.number,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HelplineEntry {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String number;
  final String note;
  const _HelplineEntry({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.number,
    required this.note,
  });
}

// ── Library Card ─────────────────────────────────────────────────────────────
class _LibraryCard extends StatelessWidget {
  final bool isDark;
  final String? universityName;
  final VoidCallback onVisitWeb;

  const _LibraryCard({
    required this.isDark,
    this.universityName,
    required this.onVisitWeb,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.book,
                  color: Color(0xFF795548),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      universityName != null
                          ? '$universityName Library'
                          : 'University Library',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Access books, journals & e-resources',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Iconsax.clock,
            label: 'Hours',
            value: 'Sun–Thu  8:00 AM – 9:00 PM\nFri–Sat  10:00 AM – 5:00 PM',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Iconsax.book_saved,
            label: 'Collections',
            value: 'Books, Journals, Dissertations, E-Resources',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Iconsax.wifi,
            label: 'Services',
            value: 'Wi-Fi, Study Rooms, Printing & Scanning',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onVisitWeb,
              icon: const Icon(Iconsax.global, size: 16),
              label: const Text('Visit Library Portal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clubs Grid ───────────────────────────────────────────────────────────────
class _ClubsGrid extends StatelessWidget {
  final bool isDark;
  const _ClubsGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final clubs = [
      _ClubEntry('💻', 'Programming\nClub', const Color(0xFF6C63FF)),
      _ClubEntry('🤖', 'Robotics\nClub', const Color(0xFF00BCD4)),
      _ClubEntry('📸', 'Photography\nClub', const Color(0xFFFF6B6B)),
      _ClubEntry('🎭', 'Drama &\nCulture Club', const Color(0xFFFF9800)),
      _ClubEntry('🌍', 'Debate\nClub', const Color(0xFF4CAF50)),
      _ClubEntry('🎵', 'Music\nClub', const Color(0xFFE91E63)),
      _ClubEntry('⚽', 'Sports\nClub', const Color(0xFF795548)),
      _ClubEntry('🔬', 'Science\nClub', const Color(0xFF009688)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clubs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final club = clubs[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D27) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: club.color.withAlpha(60), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(club.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                club.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: club.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClubEntry {
  final String emoji;
  final String name;
  final Color color;
  const _ClubEntry(this.emoji, this.name, this.color);
}

// ── App Info Card ─────────────────────────────────────────────────────────────
class _AppInfoCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPrivacyTap;
  final VoidCallback onWebsiteTap;

  const _AppInfoCard({
    required this.isDark,
    required this.onPrivacyTap,
    required this.onWebsiteTap,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      isDark: isDark,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.shield_tick,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            title: Text(
              'Privacy Policy',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'How we handle your data',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            trailing: const Icon(Iconsax.arrow_right_3, size: 18),
            onTap: onPrivacyTap,
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.global,
                color: Color(0xFF00BCD4),
                size: 22,
              ),
            ),
            title: Text(
              'Campus Saga Website',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'Learn more about the platform',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            trailing: const Icon(Iconsax.arrow_right_3, size: 18),
            onTap: onWebsiteTap,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _InfoCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: child,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black38),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
