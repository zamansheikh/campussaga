import 'package:advanced_salomon_bottom_bar/advanced_salomon_bottom_bar.dart';
import 'package:campus_saga/core/constants/update_constants.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/notifications/notification_panel.dart';
import 'package:campus_saga/core/services/update_checker.dart';
import 'package:campus_saga/core/theme/app_theme.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/pages/home/issue_page.dart';
import 'package:campus_saga/presentation/pages/home/switcher_widget.dart';
import 'package:campus_saga/presentation/pages/post/create_post_page.dart';
import 'package:campus_saga/presentation/pages/profile/profile_page.dart';
import 'package:campus_saga/presentation/pages/profile/settings_page.dart';
import 'package:campus_saga/presentation/pages/promotion/promotion_page.dart';
import 'package:campus_saga/presentation/pages/ranking/ranking_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentVersion = CURRENT_VERSION;
  int _currentIndex = 0;
  List<Widget> pages = [];

  @override
  void initState() {
    pages = [
      IssuePage(),
      PromotionPage(),
      CreatePostPage(
        onPostCreated: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      RankingPage(),
      ProfilePage(),
    ];
    Future.delayed(const Duration(seconds: 5), () async {
      _currentVersion = await checkUpdateFromGithub(context);
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        if (isOpen) FocusScope.of(context).unfocus();
      },
      endDrawer: const NotificationPanel(),

      // ── Polished Drawer ───────────────────────────────────────────
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(30),
                      border: Border.all(
                        color: Colors.white.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Iconsax.book_1,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Campus Saga',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Your campus voice',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Iconsax.home_2,
                    label: 'Home',
                    selected: _currentIndex == 0,
                    onTap: () {
                      setState(() => _currentIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.award,
                    label: 'Promotions',
                    selected: _currentIndex == 1,
                    onTap: () {
                      setState(() => _currentIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.add_square,
                    label: 'Create Post',
                    selected: _currentIndex == 2,
                    onTap: () {
                      setState(() => _currentIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.ranking,
                    label: 'Rankings',
                    selected: _currentIndex == 3,
                    onTap: () {
                      setState(() => _currentIndex = 3);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.profile_circle,
                    label: 'Profile',
                    selected: _currentIndex == 4,
                    onTap: () {
                      setState(() => _currentIndex = 4);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.repeat,
                    label: 'Switch Campus',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      showSwitcherWidget(context);
                    },
                  ),
                  const Divider(height: 24),
                  _DrawerItem(
                    icon: Iconsax.notification,
                    label: 'Notifications',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Future.microtask(
                        () => _scaffoldKey.currentState?.openEndDrawer(),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.setting_2,
                    label: 'Settings',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.info_circle,
                    label: 'About App',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: CURRENT_VERSION == _currentVersion
                        ? Iconsax.tick_circle
                        : Iconsax.refresh,
                    label: CURRENT_VERSION == _currentVersion
                        ? 'Up to date'
                        : 'Update: $_currentVersion',
                    selected: false,
                    onTap: () {
                      checkUpdateFromGithub(context);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Iconsax.logout,
                    label: 'Logout',
                    selected: false,
                    isDestructive: true,
                    onTap: () async {
                      sl<AuthBloc>().add(SignOutEvent());
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: IndexedStack(index: _currentIndex, children: pages),

      // ── Polished Bottom Nav ───────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2024) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: AdvancedSalomonBottomBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: [
                AdvancedSalomonBottomBarItem(
                  icon: const Icon(Iconsax.home_2),
                  title: Text(
                    'Home',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selectedColor: AppColors.primary,
                ),
                AdvancedSalomonBottomBarItem(
                  icon: const Icon(Iconsax.award),
                  title: Text(
                    'Promotions',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selectedColor: const Color(0xFF7C4DFF),
                ),
                AdvancedSalomonBottomBarItem(
                  icon: const Icon(Iconsax.add_square),
                  title: Text(
                    'Post',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selectedColor: const Color(0xFF00BCD4),
                ),
                AdvancedSalomonBottomBarItem(
                  icon: const Icon(Iconsax.ranking),
                  title: Text(
                    'Rankings',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selectedColor: const Color(0xFF4CAF50),
                ),
                AdvancedSalomonBottomBarItem(
                  icon: const Icon(Iconsax.profile_circle),
                  title: Text(
                    'Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selectedColor: const Color(0xFFFF6B6B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drawer item widget ────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isDestructive
        ? const Color(0xFFEF5350)
        : AppColors.primary;
    final Color textColor = selected
        ? activeColor
        : isDestructive
        ? const Color(0xFFEF5350)
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected ? activeColor.withAlpha(20) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: selected ? activeColor : textColor,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
