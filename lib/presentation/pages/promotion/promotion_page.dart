import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/notifications/notification_sheet.dart';
import 'package:campus_saga/core/theme/app_theme.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/presentation/bloc/ads/ads_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/pages/promotion/promotion_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  // Example list of promotions - normally this data would come from a backend or database
  List<Promotion> promotions = [];
  var userState = null;
  @override
  void initState() {
    fetchUser();
    _fetchAds();
    super.initState();
  }

  void fetchUser() {
    final state = sl<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      setState(() {
        userState = state.user;
      });
    }
  }

  void _fetchAds() {
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
      sl<AdsBloc>().add(FetchAdsEvent());
    }
  }

  String getUserId() {
    try {
      return userState.user.id;
    } catch (e) {
      return '';
    }
  }

  void toggleTrueVote(Promotion promotion) {
    int index = promotions.indexOf(promotion);
    setState(() {
      promotions[index] = promotion.toggleTrueVote(
        getUserId(),
      ); // Example userId
    });
    sl<AdsBloc>().add(UpdateAdsEvent(promotions[index]));
  }

  void toggleFalseVote(Promotion promotion) {
    int index = promotions.indexOf(promotion);
    setState(() {
      promotions[index] = promotion.toggleFalseVote(
        getUserId(),
      ); // Example userId
    });
    sl<AdsBloc>().add(UpdateAdsEvent(promotions[index]));
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
                  colors: [Color(0xFF7C4DFF), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.award, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              'Promotions',
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
      body: BlocConsumer<AdsBloc, AdsState>(
        listener: (context, state) {
          if (state is AdsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdsError) {
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
                  Text(state.message, style: GoogleFonts.poppins(fontSize: 14)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _fetchAds,
                    icon: const Icon(Iconsax.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdsLoaded && state.promotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.award,
                      size: 48,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No promotions yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check back later for events!',
                    style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Iconsax.refresh, size: 16),
                    label: const Text('Refresh'),
                    onPressed: _fetchAds,
                  ),
                ],
              ),
            );
          }

          if (state is AdsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdsLoaded) {
            promotions = state.promotions;

            return RefreshIndicator(
              onRefresh: () async => _fetchAds(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final promotion = promotions[index];
                  final timeLeft = promotion.expiryDate != null
                      ? promotion.expiryDate!
                            .difference(DateTime.now())
                            .inHours
                            .toString()
                      : null;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PromotionDetailPage(promotion: promotion),
                        ),
                      );
                    },
                    child: PromotionCardNew(
                      club: promotion.clubName,
                      title: promotion.promotionTitle,
                      imageUrl: promotion.imageUrls.isNotEmpty
                          ? promotion.imageUrls.first
                          : 'https://placehold.co/600x400',
                      date: DateFormat.yMMMd().format(promotion.timestamp),
                      timeLeft: timeLeft,
                      onTrueVote: () => toggleTrueVote(promotion),
                      onFalseVote: () => toggleFalseVote(promotion),
                      likes: promotion.likes,
                      dislikes: promotion.dislikes,
                      hasUserVotedTrue: promotion.hasUserVotedTrue(getUserId()),
                      hasUserVotedFalse: promotion.hasUserVotedFalse(
                        getUserId(),
                      ),
                      eventLink: promotion.eventLink,
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: Text("Something went wrong"));
        },
      ),
    );
  }
}

class PromotionCardNew extends StatelessWidget {
  final String club;
  final String title;
  final String imageUrl;
  final String date;
  final String? timeLeft;
  final VoidCallback onTrueVote;
  final VoidCallback onFalseVote;
  final int likes;
  final int dislikes;
  final bool hasUserVotedTrue;
  final bool hasUserVotedFalse;
  final String? eventLink;

  const PromotionCardNew({
    Key? key,
    required this.club,
    required this.title,
    required this.imageUrl,
    required this.date,
    this.timeLeft,
    required this.onTrueVote,
    required this.onFalseVote,
    required this.likes,
    required this.dislikes,
    required this.hasUserVotedTrue,
    required this.hasUserVotedFalse,
    this.eventLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner image with overlays ──────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xFFF0F2FF),
                    child: const Center(
                      child: Icon(
                        Iconsax.image,
                        size: 48,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              ),
              // Club badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    club,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Time left badge
              if (timeLeft != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.clock,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$timeLeft h left',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Iconsax.calendar_1,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Actions row ─────────────────────────────────
                Row(
                  children: [
                    // Like
                    _VoteButton(
                      icon: Iconsax.like_1,
                      activeIcon: Iconsax.like,
                      count: likes,
                      active: hasUserVotedTrue,
                      activeColor: AppColors.primary,
                      onTap: onTrueVote,
                    ),
                    const SizedBox(width: 8),
                    // Dislike
                    _VoteButton(
                      icon: Iconsax.dislike,
                      activeIcon: Iconsax.dislike,
                      count: dislikes,
                      active: hasUserVotedFalse,
                      activeColor: Colors.red,
                      onTap: onFalseVote,
                    ),
                    const Spacer(),
                    // Learn More
                    FilledButton.icon(
                      onPressed: () =>
                          eventLink != null ? launchURL(eventLink!) : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Iconsax.link_21, size: 14),
                      label: Text(
                        'Learn More',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vote button helper ───────────────────────────────────────────

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? activeColor.withAlpha(80)
                : Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 16,
              color: active ? activeColor : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? activeColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
