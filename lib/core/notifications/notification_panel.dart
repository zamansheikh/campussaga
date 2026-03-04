import 'package:campussaga/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

// ---------------------------------------------------------------------------
// Demo notification model
// ---------------------------------------------------------------------------
class _AppNotification {
  final String id;
  final String title;
  final String body;
  final _NotifType type;
  final DateTime time;
  bool isRead;

  _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}

enum _NotifType { issue, resolved, vote, announcement, achievement, system }

// ---------------------------------------------------------------------------
// Demo data
// ---------------------------------------------------------------------------
final _demoNotifs = <_AppNotification>[
  _AppNotification(
    id: '1',
    title: 'New Issue Reported',
    body: 'A classmate raised a problem about the library AC in Room 203.',
    type: _NotifType.issue,
    time: DateTime.now().subtract(const Duration(minutes: 3)),
  ),
  _AppNotification(
    id: '2',
    title: 'Issue Resolved 🎉',
    body: 'The internet outage in Block C has been resolved by admin.',
    type: _NotifType.resolved,
    time: DateTime.now().subtract(const Duration(hours: 1)),
    isRead: true,
  ),
  _AppNotification(
    id: '3',
    title: 'Your Post Got Votes',
    body: '12 students agreed with your post about canteen food quality.',
    type: _NotifType.vote,
    time: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  _AppNotification(
    id: '4',
    title: '📢 Campus Announcement',
    body:
        'End semester exams schedule has been published. Check the notice board.',
    type: _NotifType.announcement,
    time: DateTime.now().subtract(const Duration(hours: 6)),
    isRead: true,
  ),
  _AppNotification(
    id: '5',
    title: 'Achievement Unlocked!',
    body: 'You earned the "Issue Resolver" badge for 5 resolved issues.',
    type: _NotifType.achievement,
    time: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  _AppNotification(
    id: '6',
    title: 'Campus Saga Update',
    body: 'New features are available! Check out the ranking system.',
    type: _NotifType.system,
    time: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  _AppNotification(
    id: '7',
    title: 'Trending Post Alert',
    body: 'A post about parking shortage is trending at your university.',
    type: _NotifType.issue,
    time: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
  ),
  _AppNotification(
    id: '8',
    title: 'New Comment on Your Post',
    body: 'A student commented: "I fully agree with this. We need a solution!"',
    type: _NotifType.vote,
    time: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
  ),
  _AppNotification(
    id: '9',
    title: '🏆 Weekly Ranking Update',
    body: 'Your university moved up to #3 in the national ranking this week.',
    type: _NotifType.achievement,
    time: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),
  _AppNotification(
    id: '10',
    title: 'Maintenance Notice',
    body: 'The app will be under maintenance on Sunday 2–4 AM.',
    type: _NotifType.system,
    time: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),
];

// ---------------------------------------------------------------------------
// Notification Panel (right EndDrawer)
// ---------------------------------------------------------------------------
class NotificationPanel extends StatefulWidget {
  const NotificationPanel({Key? key}) : super(key: key);

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final List<_AppNotification> _notifs = List.from(_demoNotifs);

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n.isRead = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      _notifs.firstWhere((n) => n.id == id).isRead = true;
    });
  }

  void _dismiss(String id) {
    setState(() {
      _notifs.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              16,
              16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.notification, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Text(
                          '$_unreadCount unread',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white38, width: 1),
                      ),
                    ),
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────
          if (_notifs.isEmpty)
            Expanded(child: _buildEmpty())
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _notifs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: colorScheme.outline.withAlpha(30),
                ),
                itemBuilder: (_, i) => _NotifTile(
                  notif: _notifs[i],
                  onTap: () => _markRead(_notifs[i].id),
                  onDismiss: () => _dismiss(_notifs[i].id),
                ),
              ),
            ),

          // ── Footer ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    label: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.notification_status,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No new notifications',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single notification tile with swipe-to-dismiss
// ---------------------------------------------------------------------------
class _NotifTile extends StatelessWidget {
  final _AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = notif.isRead
        ? Colors.transparent
        : (isDark
              ? AppColors.primary.withAlpha(14)
              : AppColors.primary.withAlpha(10));

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withAlpha(200),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconBgColor(notif.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconData(notif.type),
                  size: 18,
                  color: _iconFgColor(notif.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: notif.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 11,
                          color: const Color(0xFFBDBDBD),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(notif.time),
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFFBDBDBD),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _iconBgColor(_NotifType t) {
    switch (t) {
      case _NotifType.issue:
        return const Color(0xFFFFEBEE);
      case _NotifType.resolved:
        return const Color(0xFFE8F5E9);
      case _NotifType.vote:
        return const Color(0xFFE3F2FD);
      case _NotifType.announcement:
        return const Color(0xFFFFF8E1);
      case _NotifType.achievement:
        return const Color(0xFFF3E5F5);
      case _NotifType.system:
        return const Color(0xFFECEFF1);
    }
  }

  Color _iconFgColor(_NotifType t) {
    switch (t) {
      case _NotifType.issue:
        return const Color(0xFFE53935);
      case _NotifType.resolved:
        return const Color(0xFF43A047);
      case _NotifType.vote:
        return const Color(0xFF1E88E5);
      case _NotifType.announcement:
        return const Color(0xFFFFB300);
      case _NotifType.achievement:
        return const Color(0xFF8E24AA);
      case _NotifType.system:
        return const Color(0xFF607D8B);
    }
  }

  IconData _iconData(_NotifType t) {
    switch (t) {
      case _NotifType.issue:
        return Iconsax.shield_cross;
      case _NotifType.resolved:
        return Iconsax.tick_circle;
      case _NotifType.vote:
        return Iconsax.like_1;
      case _NotifType.announcement:
        return Iconsax.speaker;
      case _NotifType.achievement:
        return Iconsax.award;
      case _NotifType.system:
        return Iconsax.setting_2;
    }
  }
}
