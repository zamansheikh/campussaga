// lib/presentation/pages/auth/onboarding_page.dart

import 'package:campus_saga/presentation/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const List<_OnboardSlide> _slides = [
    _OnboardSlide(
      lottieAsset: 'assets/lottie/campus.json',
      useIconFallback: false,
      iconFallback: Iconsax.book_1,
      iconColor: Color(0xFF3D5AFE),
      title: 'Welcome to\nCampus Saga',
      subtitle:
          'Your unified campus platform to raise issues, celebrate wins, and connect with your university community.',
      gradient: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
    ),
    _OnboardSlide(
      lottieAsset: '',
      useIconFallback: true,
      iconFallback: Iconsax.message_edit,
      iconColor: Color(0xFF7C4DFF),
      title: 'Share Your\nCampus Voice',
      subtitle:
          'Post issues, share promotions, and highlight achievements. Your voice shapes the future of your campus.',
      gradient: [Color(0xFF7C4DFF), Color(0xFF9C27B0)],
    ),
    _OnboardSlide(
      lottieAsset: 'assets/lottie/on_start.json',
      useIconFallback: false,
      iconFallback: Iconsax.people,
      iconColor: Color(0xFF00BCD4),
      title: 'Verified &\nTrusted Community',
      subtitle:
          'Only verified students and faculty. Real issues, real solutions, built by your campus for your campus.',
      gradient: [Color(0xFF0277BD), Color(0xFF00BCD4)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
      _fadeController.forward();
    } else {
      _completeOnboarding();
    }
  }

  void _skip() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Skip button ──────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Illustration area ────────────────────────────────
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) =>
                      _IllustrationPanel(slide: _slides[index]),
                ),
              ),

              // ── Bottom card ──────────────────────────────────────
              _BottomCard(
                slide: slide,
                currentPage: _currentPage,
                totalPages: _slides.length,
                isLast: isLast,
                onNext: _nextPage,
                fadeAnimation: _fadeAnimation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Illustration panel ───────────────────────────────────────────────────────

class _IllustrationPanel extends StatelessWidget {
  final _OnboardSlide slide;
  const _IllustrationPanel({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: slide.useIconFallback
          ? _IconIllustration(slide: slide)
          : _LottieIllustration(slide: slide),
    );
  }
}

class _LottieIllustration extends StatelessWidget {
  final _OnboardSlide slide;
  const _LottieIllustration({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        slide.lottieAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _IconIllustration(slide: slide),
      ),
    );
  }
}

class _IconIllustration extends StatelessWidget {
  final _OnboardSlide slide;
  const _IconIllustration({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(30),
          border: Border.all(color: Colors.white.withAlpha(60), width: 2),
        ),
        child: Icon(slide.iconFallback, size: 100, color: Colors.white),
      ),
    );
  }
}

// ── Bottom card ──────────────────────────────────────────────────────────────

class _BottomCard extends StatelessWidget {
  final _OnboardSlide slide;
  final int currentPage;
  final int totalPages;
  final bool isLast;
  final VoidCallback onNext;
  final Animation<double> fadeAnimation;

  const _BottomCard({
    required this.slide,
    required this.currentPage,
    required this.totalPages,
    required this.isLast,
    required this.onNext,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1E2D),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),

            // Dots + Next button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dot indicators
                Row(
                  children: List.generate(
                    totalPages,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == currentPage ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == currentPage
                            ? slide.gradient.first
                            : const Color(0xFFCDD0F0),
                      ),
                    ),
                  ),
                ),

                // Next / Get Started button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slide.gradient.first,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isLast ? 28 : 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLast
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Started',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Iconsax.arrow_right_1, size: 18),
                            ],
                          )
                        : const Icon(Iconsax.arrow_right_1, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────

class _OnboardSlide {
  final String lottieAsset;
  final bool useIconFallback;
  final IconData iconFallback;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardSlide({
    required this.lottieAsset,
    required this.useIconFallback,
    required this.iconFallback,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
