import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../voice/presentation/widgets/post_card.dart';
import '../growth_text.dart';

/// Another student's profile (`/u/:id`): who they are, their roles and
/// public badges, and their named Campus posts. The photo shows only when
/// the server sends it (people who share a class group), else initials.
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, required this.userId});

  final String userId;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  StudentProfile? _profile;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await getIt<GrowthRepository>().studentProfile(widget.userId);
      if (mounted) {
        setState(() {
          _profile = p;
          _failure = null;
        });
      }
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = _profile;
    final failure = _failure;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: SafeArea(
        child: profile != null
            ? RefreshIndicator(
                onRefresh: _load,
                child: _ProfileView(profile: profile),
              )
            : failure != null
            ? CsEmptyState(
                icon: CsIcons.offline,
                title: failure is NotFoundFailure
                    ? l10n.profileNotFound
                    : growthErrorText(l10n, failure),
                actionLabel: failure is NotFoundFailure ? null : l10n.tryAgain,
                onAction: failure is NotFoundFailure
                    ? null
                    : () {
                        setState(() => _failure = null);
                        _load();
                      },
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final p = profile;
    final name = p.name.isEmpty ? l10n.unnamedStudent : p.name;
    final roles = [
      for (final r in p.roles)
        if (roleName(l10n, r) case final label?) (r, label),
    ];
    final muted = context.text.bodyMedium?.copyWith(color: cs.textSecondary);
    return CsPage(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(CsSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      userId: p.id,
                      name: name,
                      photoVersion: p.photoVersion,
                      googlePhotoUrl: p.googlePhotoUrl,
                      size: 60,
                    ),
                    const SizedBox(width: CsSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: context.text.titleLarge,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.verified) ...[
                                const SizedBox(width: CsSpace.xs),
                                Icon(
                                  CsIcons.verified,
                                  size: 18,
                                  color: cs.primary,
                                  semanticLabel: l10n.verifiedStudent,
                                ),
                              ],
                              if (p.featuredBadge case final b?) ...[
                                const SizedBox(width: CsSpace.xs),
                                CsBadgeIcon(
                                  badgeKey: b.key,
                                  tier: b.tier,
                                  size: 22,
                                  semanticLabel: badgeName(l10n, b.key),
                                ),
                              ],
                            ],
                          ),
                          if (p.universityName.isNotEmpty)
                            Text(p.universityName, style: muted),
                          if (p.classLine.isNotEmpty)
                            Text(p.classLine, style: muted),
                          if (p.joinedAt != null)
                            Text(
                              l10n.profileJoined(monthYear(l10n, p.joinedAt!)),
                              style: context.text.bodySmall?.copyWith(
                                color: cs.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (roles.isNotEmpty || p.invitesJoined > 0) ...[
                  const SizedBox(height: CsSpace.md),
                  Wrap(
                    spacing: CsSpace.sm,
                    runSpacing: CsSpace.sm,
                    children: [
                      for (final (key, label) in roles)
                        CsPill(icon: CsIcons.badge(key), label: label),
                      if (p.invitesJoined > 0)
                        CsPill(
                          icon: CsIcons.invite,
                          label: l10n.profileInvitesJoined(p.invitesJoined),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (p.badges.isNotEmpty) ...[
          const SizedBox(height: CsSpace.lg),
          CsSectionTitle(title: l10n.badgesTitle),
          Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CsRadius.lg),
              side: BorderSide(color: cs.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CsSpace.sm),
              child: CsBadgeGrid(
                children: [
                  for (final b in p.badges)
                    CsBadgeTile(
                      badgeKey: b.key,
                      name: badgeName(l10n, b.key),
                      tier: b.tier,
                      caption: b.private
                          ? l10n.badgePrivateNote
                          : tierName(l10n, b.tier),
                      private: b.private,
                      privateLabel: l10n.badgePrivateNote,
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: CsSpace.lg),
        CsSectionTitle(title: l10n.profilePostsTitle),
        if (p.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(CsSpace.xs),
            child: Text(l10n.profileNoPosts, style: muted),
          )
        else
          for (final post in p.posts)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.md),
              child: PostCard(
                card: post,
                // Reading here; reacting and commenting happen on the post.
                onReact: (_) => context.push(Routes.campusIssue(post.id)),
                onComment: () =>
                    context.push(Routes.campusIssue(post.id, comment: true)),
                onOpen: () => context.push(Routes.campusIssue(post.id)),
              ),
            ),
      ],
    );
  }
}
