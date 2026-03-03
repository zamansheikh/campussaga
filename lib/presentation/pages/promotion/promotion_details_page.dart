import 'package:campus_saga/core/theme/app_theme.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class PromotionDetailPage extends StatelessWidget {
  final Promotion promotion;

  const PromotionDetailPage({Key? key, required this.promotion})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeLeft = promotion.expiryDate != null
        ? promotion.expiryDate!.difference(DateTime.now()).inHours
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1D2024) : Colors.white,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withAlpha(80),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_left,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    promotion.imageUrls.isNotEmpty
                        ? promotion.imageUrls.first
                        : 'https://placehold.co/600x400',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF0F2FF),
                      child: const Center(
                        child: Icon(
                          Iconsax.image,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Club badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promotion.clubName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (timeLeft != null && timeLeft > 0)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$timeLeft h left',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
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
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    promotion.promotionTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date row
                  _InfoRow(
                    icon: Iconsax.calendar_1,
                    text:
                        'Posted on ${DateFormat.yMMMd().format(promotion.timestamp)}',
                  ),
                  if (timeLeft != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Iconsax.clock,
                      text: timeLeft > 0
                          ? '$timeLeft hours remaining'
                          : 'Event has ended',
                      color: timeLeft > 0 ? Colors.orange.shade700 : Colors.red,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Description heading
                  Text(
                    'About This Event',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    promotion.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Votes row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2140)
                          : const Color(0xFFF5F6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(40),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.like_1,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${promotion.likes} likes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Iconsax.dislike,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${promotion.dislikes} dislikes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Event link CTA
                  if (promotion.eventLink != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => launchURL(promotion.eventLink!),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Iconsax.link_21, size: 18),
                        label: Text(
                          'Go to Event',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row helper ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF9CA3AF);
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.poppins(fontSize: 12, color: c)),
      ],
    );
  }
}
