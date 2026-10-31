import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/clock.dart';
import '../../../../app/env.dart';
import '../../../../app/router.dart';
import '../../../classes/presentation/class_format.dart';
import '../../../growth/presentation/growth_text.dart';
import '../voice_format.dart';
import 'voice_image.dart';

/// Any post (issue, post, question, poll) as a social card: who and when,
/// the text, photos, the poll, the reactions, and React · Comment · Share.
/// Used by the feed (a preview, tap to open) and the opened post ([full]).
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.card,
    required this.onReact,
    required this.onComment,
    this.onVote,
    this.onOpen,
    this.full = false,
    this.body,
    this.images,
    this.offline = false,
  });

  final IssueCard card;

  /// React with a reaction, or take the caller's back (null).
  final void Function(Reaction? reaction) onReact;
  final VoidCallback onComment;

  /// Vote in a poll (option id).
  final void Function(String optionId)? onVote;
  final VoidCallback? onOpen;

  /// The opened post: the whole text, flat.
  final bool full;

  /// The whole text ([full]).
  final String? body;

  /// Every photo with its size ([full]).
  final List<IssueImage>? images;

  /// Reading the saved copy: nothing can be sent.
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = card;
    final now = appNow();
    final text = full ? (body ?? c.preview) : c.preview;
    final photos = images ?? c.shownImages;
    return CsPostCard(
      framed: !full,
      onTap: onOpen,
      header: CsPostHeader(
        avatar: postAvatar(c.id, c.author, size: 42),
        name: issueAuthorLabel(l10n, c),
        nameIcon: c.anonymous
            ? CsIcons.anonymous
            : (c.author?.verified ?? false)
            ? CsIcons.verified
            : null,
        // A named author's badge, and their name opens their profile (only
        // when the server says who: anonymous posts never do).
        badges: [
          if (c.author?.featuredBadge case final b?)
            CsBadgeIcon(
              badgeKey: b.key,
              tier: b.tier,
              size: 18,
              semanticLabel: badgeName(l10n, b.key),
            ),
        ],
        onTap: c.author?.id == null
            ? null
            : () => context.push(Routes.student(c.author!.id!)),
        subtitle: [
          agoText(context, c.createdAt, now),
          categoryLabel(l10n, c.category),
        ].join(' · '),
        trailing: _badge(l10n, c),
      ),
      title: c.isIssue ? c.title : null,
      text: text,
      textCut: !full && c.previewCut,
      moreLabel: l10n.campusSeeMore,
      maxLines: full ? null : (c.isIssue ? 3 : 6),
      bigText:
          c.kind == PostKind.question ||
          c.kind == PostKind.poll ||
          (c.kind == PostKind.post &&
              photos.isEmpty &&
              text.characters.length <= 90),
      tags: [
        if (c.campusOnly && !c.visitor)
          CsBadge(
            label: l10n.campusOnlyBadge,
            icon: CsIcons.lock,
            tone: CsBadgeTone.neutral,
          ),
        if (c.private)
          CsBadge(
            label: l10n.voicePrivate,
            icon: CsIcons.lock,
            tone: CsBadgeTone.danger,
          ),
        if (c.locationLabel.isNotEmpty)
          CsBadge(
            label: c.locationLabel,
            icon: CsIcons.place,
            tone: CsBadgeTone.neutral,
          ),
      ],
      media: photos.isEmpty
          ? null
          : CsMediaGrid(
              count: photos.length > 4 ? 4 : photos.length,
              aspect: photos.first.width > 0 ? photos.first.aspect : null,
              builder: (_, i) => VoiceImage(
                photos[i].id,
                // Large tiles load the full photo; the small ones of a
                // 3–4 photo grid make do with the thumbnail.
                thumb: !full && photos.length > 2 && i > 0,
                fit: BoxFit.cover,
              ),
              onTap: (i) => showPhotoViewer(context, photos, i),
              semanticLabel: (i) => l10n.voicePhoto(i + 1),
            ),
      extra: c.poll == null ? null : _poll(context, c.poll!, now),
      summary: _summary(context, c),
      actions: CsActionBar(
        children: [
          _ReactButton(card: c, onReact: offline ? null : onReact),
          CsActionButton(
            icon: CsIcons.comment,
            label: c.kind == PostKind.question
                ? l10n.campusAnswer
                : l10n.campusComment,
            onTap: offline ? null : onComment,
          ),
          CsActionButton(
            icon: CsIcons.share,
            label: l10n.campusShare,
            onTap: () => sharePost(context, c),
          ),
        ],
      ),
    );
  }

  Widget? _badge(AppLocalizations l10n, IssueCard c) {
    if (c.isIssue || c.visibility != ContentVisibility.visible) {
      return issueChip(l10n, c);
    }
    return switch (c.kind) {
      PostKind.question => CsBadge(
        label: l10n.campusBadgeQuestion,
        icon: CsIcons.question,
      ),
      PostKind.poll => CsBadge(label: l10n.campusBadgePoll, icon: CsIcons.poll),
      _ => null,
    };
  }

  Widget _poll(BuildContext context, Poll poll, DateTime now) {
    final total = poll.options.fold<int>(0, (a, o) => a + (o.votes ?? 0));
    final canVote =
        onVote != null &&
        !card.visitor &&
        !offline &&
        poll.myVote == null &&
        !poll.isClosed(now) &&
        card.visibility == ContentVisibility.visible;
    return CsPollView(
      choices: [
        for (final o in poll.options)
          CsPollChoice(
            label: o.label,
            share: o.votes == null
                ? null
                : total == 0
                ? 0
                : o.votes! / total,
            mine: o.id == poll.myVote,
          ),
      ],
      footer: pollFooter(context, poll, now),
      percentLabel: (s) => percentText(context, s),
      onVote: canVote ? (i) => onVote!(poll.options[i].id) : null,
    );
  }

  Widget? _summary(BuildContext context, IssueCard c) {
    final l10n = AppLocalizations.of(context);
    if (c.meTooCount == 0 && c.commentCount == 0) return null;
    final emojis = c.isIssue
        ? [if (c.meTooCount > 0) Reaction.meToo.emoji]
        : [
            for (final r in c.topReactions()) r.emoji,
            // Older servers send only the total.
            if (c.reactions.isEmpty && c.meTooCount > 0) Reaction.like.emoji,
          ];
    return CsReactionSummary(
      emojis: emojis,
      countLabel: countText(context, c.meTooCount),
      trailing: c.commentCount == 0
          ? ''
          : c.kind == PostKind.question
          ? l10n.campusAnswerCount(c.commentCount)
          : l10n.campusCommentCount(c.commentCount),
      onTrailingTap: onComment,
    );
  }
}

/// Me too on issues; on the other kinds a tap gives ❤️ (or takes the
/// reaction back) and a long press opens the picker.
class _ReactButton extends StatelessWidget {
  const _ReactButton({required this.card, required this.onReact});

  final IssueCard card;
  final void Function(Reaction?)? onReact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = card;
    final mine = c.shownReaction;
    final semantics = c.isIssue
        ? l10n.voiceMeTooSemantics(c.meTooCount)
        : l10n.campusReactSemantics(c.meTooCount);
    if (c.isIssue) {
      return CsActionButton(
        icon: c.voted ? CsIcons.meTooFill : CsIcons.meToo,
        label: l10n.voiceMeToo,
        active: c.voted,
        semanticLabel: semantics,
        // You can't Me too your own issue.
        onTap: onReact == null || c.mine
            ? null
            : () => onReact!(c.voted ? null : Reaction.meToo),
      );
    }
    final react = onReact;
    return CsReactionButton(
      idleIcon: CsIcons.heart,
      emoji: mine?.emoji,
      label: reactionLabel(l10n, mine ?? Reaction.like),
      activeColor: mine == null
          ? null
          : CsReactionStyle.color(context, mine.wire),
      semanticLabel: semantics,
      options: [
        for (final r in Reaction.forPosts) (r.emoji, reactionLabel(l10n, r)),
      ],
      selected: mine == null ? null : Reaction.forPosts.indexOf(mine),
      onTap: react == null
          ? null
          : () => react(mine != null ? null : Reaction.like),
      onPicked: react == null
          ? null
          : (i) {
              final r = Reaction.forPosts[i];
              // Picking the reaction you already gave keeps it.
              if (r != mine) react(r);
            },
    );
  }
}

/// Someone on Campus: the person's initials when named, else an animal
/// face picked from [seed] (the post id for its author, a handle for
/// commenters).
Widget postAvatar(String seed, PostAuthor? author, {double size = 40}) =>
    author == null || author.name.isEmpty
    ? CsAnonAvatar(seed: seed, size: size)
    : CsAvatar(name: author.name, size: size);

/// The link that opens a post in the app (or the web page that says so).
Uri postLink(String id) => Uri.parse('${Env.siteUrl}/c/$id');

/// Shares a post: its first words and the link.
Future<void> sharePost(BuildContext context, IssueCard card) {
  final l10n = AppLocalizations.of(context);
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      text: l10n.campusShareText(
        postSnippet(card),
        postLink(card.id).toString(),
      ),
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
