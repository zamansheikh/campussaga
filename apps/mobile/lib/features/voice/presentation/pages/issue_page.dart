import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../classes/presentation/class_format.dart';
import '../../data/voice_cache.dart';
import '../bloc/issue_cubit.dart';
import '../voice_format.dart';
import '../voice_updates.dart';
import '../widgets/post_card.dart';
import '../widgets/voice_sheets.dart';

/// One post opened: the post, (issues) its status history and official
/// actions, and the comments as threads with likes and replies.
class IssuePage extends StatelessWidget {
  const IssuePage({
    super.key,
    required this.issueId,
    this.focusComment = false,
  });

  final String issueId;

  /// Opened from a Comment button: the comment box is ready.
  final bool focusComment;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => IssueCubit(
        getIt<VoiceRepository>(),
        getIt<VoiceCache>(),
        user?.id ?? '',
        issueId,
      )..load(),
      child: _IssueView(focusComment: focusComment),
    );
  }
}

class _IssueView extends StatefulWidget {
  const _IssueView({required this.focusComment});

  final bool focusComment;

  @override
  State<_IssueView> createState() => _IssueViewState();
}

class _IssueViewState extends State<_IssueView> {
  late final StreamSubscription<IssueCard> _cards;
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// The comment being answered.
  IssueComment? _replyTo;

  @override
  void initState() {
    super.initState();
    _cards = context.read<IssueCubit>().cards.listen(
      (c) => voiceUpdates.add(IssueChanged(c)),
    );
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    unawaited(_cards.cancel());
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _done(Failure? f, [String? ok]) {
    if (!mounted) return;
    if (f != null) {
      _snack(voiceErrorText(context, f));
    } else if (ok != null) {
      _snack(ok);
    }
  }

  void _reply(IssueComment c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
  }

  Future<void> _menu(String action, Issue issue) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<IssueCubit>();
    switch (action) {
      case 'report':
        final r = await showReportSheet(context);
        if (r == null) return;
        _done(await cubit.report(r.$1, r.$2), l10n.voiceReportSent);
      case 'edit':
        final changed = await _showEditSheet(context, issue);
        if (changed == null) return;
        _done(
          await cubit.edit(
            title: changed.$1,
            body: changed.$2,
            place: changed.$3,
          ),
        );
      case 'delete':
        final ok = await confirmDestructive(
          context,
          title: issue.card.isIssue
              ? l10n.voiceDeleteIssueTitle
              : l10n.campusDeletePostTitle,
          body: l10n.voiceDeleteIssueBody,
          action: l10n.deleteAction,
        );
        if (!ok) return;
        final f = await cubit.delete();
        _done(f);
        if (f == null && mounted) {
          voiceUpdates.add(IssueDeleted(issue.id));
          context.pop();
        }
      case 'reopen':
        final note = await showTextSheet(
          context,
          title: l10n.voiceReopenTitle,
          hint: l10n.voiceReopenHint,
          action: l10n.voiceReopen,
        );
        if (note == null) return;
        _done(await cubit.reopen(note));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = context.watch<IssueCubit>().state;
    final issue = s.issue;
    final cubit = context.read<IssueCubit>();
    return Scaffold(
      appBar: AppBar(
        title: issue == null
            ? null
            : Text(
                issue.card.kind == PostKind.question
                    ? l10n.campusBadgeQuestion
                    : kindLabel(l10n, issue.card.kind),
              ),
        actions: [
          if (issue != null && !s.offline) ...[
            IconButton(
              tooltip: issue.card.following
                  ? l10n.voiceFollowing
                  : l10n.voiceFollow,
              isSelected: issue.card.following,
              icon: const Icon(CsIcons.bell),
              selectedIcon: const Icon(CsIcons.bellActive),
              onPressed: () async => _done(await cubit.toggleFollow()),
            ),
            PopupMenuButton<String>(
              icon: const Icon(CsIcons.more),
              onSelected: (a) => _menu(a, issue),
              itemBuilder: (_) => [
                if (!issue.card.mine)
                  PopupMenuItem(value: 'report', child: Text(l10n.voiceReport)),
                if (issue.can.edit)
                  PopupMenuItem(value: 'edit', child: Text(l10n.editAction)),
                if (issue.can.reopen)
                  PopupMenuItem(value: 'reopen', child: Text(l10n.voiceReopen)),
                if (issue.can.delete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.deleteAction),
                  ),
              ],
            ),
          ],
        ],
      ),
      body: switch (issue) {
        null when s.loading => const Center(child: CircularProgressIndicator()),
        null => CsEmptyState(
          icon: CsIcons.searchEmpty,
          title: voiceErrorText(
            context,
            s.failure ?? const UnexpectedFailure(),
          ),
          actionLabel: l10n.tryAgain,
          onAction: cubit.load,
        ),
        final issue => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.load,
                child: _Body(
                  issue: issue,
                  state: s,
                  scroll: _scroll,
                  onResult: _done,
                  onReply: _reply,
                  onComment: _focus.requestFocus,
                ),
              ),
            ),
            if (!s.offline &&
                issue.card.visibility != ContentVisibility.removed)
              _Composer(
                focus: _focus,
                kind: issue.card.kind,
                replyTo: _replyTo,
                replyName: _replyTo == null
                    ? null
                    : commentWho(l10n, _replyTo!),
                onCancelReply: () => setState(() => _replyTo = null),
                onSent: () => setState(() => _replyTo = null),
                onResult: _done,
              ),
          ],
        ),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.issue,
    required this.state,
    required this.scroll,
    required this.onResult,
    required this.onReply,
    required this.onComment,
  });

  final Issue issue;
  final IssueState state;
  final ScrollController scroll;
  final void Function(Failure?, [String?]) onResult;
  final void Function(IssueComment) onReply;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<IssueCubit>();
    final c = issue.card;
    final question = c.kind == PostKind.question;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: CsSpace.xl),
      children: [
        if (state.offline || _notices(l10n, issue).isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm,
              CsSpace.md,
              0,
            ),
            child: Column(
              children: [
                if (state.offline)
                  _Note(icon: CsIcons.offline, text: l10n.errorNetwork),
                ..._notices(l10n, issue),
              ],
            ),
          ),
        PostCard(
          card: c,
          full: true,
          body: issue.body,
          images: issue.images.isEmpty ? null : issue.images,
          offline: state.offline,
          onReact: (r) async => onResult(await cubit.react(r)),
          onComment: onComment,
          onVote: (o) async => onResult(await cubit.votePoll(o)),
        ),
        Divider(height: 8, thickness: 8, color: context.cs.surfaceVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.md,
            CsSpace.md,
            CsSpace.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (issue.can.changeStatus || issue.can.officialReply) ...[
                _OfficialActions(issue: issue, onResult: onResult),
                const SizedBox(height: CsSpace.lg),
              ],
              if (c.isIssue) ...[
                _Title(l10n.voiceStatusHistory),
                CsStatusTimeline(steps: _steps(context, issue)),
                const SizedBox(height: CsSpace.lg),
              ],
              _Title(
                question
                    ? l10n.campusAnswerCount(state.comments.length)
                    : l10n.campusCommentCount(state.comments.length),
              ),
              if (state.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: CsSpace.md),
                  child: Text(
                    l10n.voiceNoComments,
                    style: context.text.bodyMedium,
                  ),
                ),
              _Threads(
                issueId: issue.id,
                comments: state.comments,
                onResult: onResult,
                onReply: onReply,
                offline: state.offline,
              ),
              if (state.commentsCursor != null)
                Center(
                  child: TextButton(
                    onPressed: state.loadingMore
                        ? null
                        : cubit.loadMoreComments,
                    child: Text(l10n.voiceLoadMore),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _notices(AppLocalizations l10n, Issue issue) {
    final c = issue.card;
    return [
      if (c.visibility == ContentVisibility.removed)
        _Note(
          icon: CsIcons.delete,
          text: issue.removedReason.isEmpty
              ? l10n.voiceRemovedByYou
              : l10n.voiceRemovedNotice(issue.removedReason),
        ),
      if (c.visibility == ContentVisibility.held)
        _Note(
          icon: CsIcons.pending,
          text: [
            l10n.voiceHeldNotice,
            holdReasonText(l10n, issue.holdReason),
          ].where((t) => t.isNotEmpty).join(' '),
        ),
      if (c.visibility == ContentVisibility.hidden)
        _Note(
          icon: CsIcons.hidden,
          text: issue.holdReason == 'moderator'
              ? l10n.voiceHeldModerator
              : l10n.voiceHiddenNotice,
        ),
      if (c.private) _Note(icon: CsIcons.lock, text: l10n.voicePrivateNotice),
    ];
  }

  List<CsTimelineStep> _steps(BuildContext context, Issue issue) {
    final l10n = AppLocalizations.of(context);
    return [
      CsTimelineStep(
        tone: CsIssueTone.open,
        title: l10n.voiceRaised,
        subtitle: shortDay(context, issue.card.createdAt),
      ),
      for (final e in issue.timeline)
        CsTimelineStep(
          tone: statusTone(e.to),
          title: statusLabel(l10n, e.to),
          subtitle: l10n.voiceStepBy(
            actorLabel(l10n, e),
            shortDay(context, e.createdAt),
          ),
          note: e.note,
        ),
    ];
  }
}

/// Comments in threads: each comment with its replies under it (the first
/// two, then "View N replies").
class _Threads extends StatefulWidget {
  const _Threads({
    required this.issueId,
    required this.comments,
    required this.onResult,
    required this.onReply,
    required this.offline,
  });

  final String issueId;
  final List<IssueComment> comments;
  final void Function(Failure?, [String?]) onResult;
  final void Function(IssueComment) onReply;
  final bool offline;

  @override
  State<_Threads> createState() => _ThreadsState();
}

class _ThreadsState extends State<_Threads> {
  final _open = <String>{};

  static const _shown = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ids = {for (final c in widget.comments) c.id};
    final replies = <String, List<IssueComment>>{};
    final top = <IssueComment>[];
    for (final c in widget.comments) {
      final p = c.parentId;
      if (p != null && ids.contains(p)) {
        (replies[p] ??= []).add(c);
      } else {
        top.add(c);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in top) ...[
          _CommentTile(
            issueId: widget.issueId,
            comment: c,
            onResult: widget.onResult,
            onReply: widget.offline ? null : () => widget.onReply(c),
          ),
          if (replies[c.id] case final list?) ...[
            for (final r
                in _open.contains(c.id) || list.length <= _shown
                    ? list
                    : list.take(_shown))
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: _CommentTile(
                  issueId: widget.issueId,
                  comment: r,
                  small: true,
                  onResult: widget.onResult,
                  // A reply to a reply joins the same thread.
                  onReply: widget.offline ? null : () => widget.onReply(r),
                ),
              ),
            if (list.length > _shown)
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: CsSpace.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => setState(
                      () => _open.contains(c.id)
                          ? _open.remove(c.id)
                          : _open.add(c.id),
                    ),
                    icon: const Icon(CsIcons.reply, size: 16),
                    label: Text(
                      _open.contains(c.id)
                          ? l10n.campusHideReplies
                          : l10n.campusViewReplies(list.length - _shown),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.issueId,
    required this.comment,
    required this.onResult,
    this.onReply,
    this.small = false,
  });

  final String issueId;
  final IssueComment comment;
  final void Function(Failure?, [String?]) onResult;
  final VoidCallback? onReply;

  /// A reply (smaller avatar).
  final bool small;

  Future<void> _menu(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<IssueCubit>();
    final c = comment;
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.mine)
              ListTile(
                leading: const Icon(CsIcons.delete),
                title: Text(l10n.deleteAction),
                onTap: () => Navigator.of(sheet).pop('delete'),
              )
            else
              ListTile(
                leading: const Icon(CsIcons.flag),
                title: Text(l10n.voiceReport),
                onTap: () => Navigator.of(sheet).pop('report'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'delete') {
      final ok = await confirmDestructive(
        context,
        title: l10n.voiceDeleteCommentTitle,
        action: l10n.deleteAction,
      );
      if (ok) onResult(await cubit.deleteComment(c.id));
    } else {
      final r = await showReportSheet(context);
      if (r == null) return;
      onResult(
        await cubit.reportComment(c.id, r.$1, r.$2),
        l10n.voiceReportSent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final c = comment;
    final cubit = context.read<IssueCubit>();
    final removed = c.visibility == ContentVisibility.removed;
    final official = c.official;
    final size = small ? 28.0 : 36.0;
    final Widget avatar = official
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CsIcons.verified,
              size: size * 0.55,
              color: cs.onPrimary,
            ),
          )
        : c.author != null
        ? postAvatar(c.id, c.author, size: size)
        // The post's anonymous author keeps the post's face.
        : CsAnonAvatar(
            seed: c.isIssueAuthor
                ? issueId
                : (c.handle.isEmpty ? c.id : c.handle),
            size: size,
          );
    final muted = context.text.labelMedium?.copyWith(
      color: cs.textSecondary,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: CsSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: removed ? null : () => _menu(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      CsSpace.sm + 4,
                      CsSpace.sm,
                      CsSpace.sm + 4,
                      CsSpace.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: official ? cs.primaryContainer : cs.surfaceVariant,
                      border: official ? Border.all(color: cs.primary) : null,
                      borderRadius: BorderRadius.circular(CsRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              commentWho(l10n, c),
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (official && c.officialTitle.isNotEmpty)
                              Text(
                                c.officialTitle,
                                style: context.text.bodySmall,
                              ),
                            if (c.isIssueAuthor && c.author != null)
                              CsBadge(label: l10n.voiceAuthorTag),
                            if (c.mine)
                              CsBadge(
                                label: l10n.voiceYou,
                                tone: CsBadgeTone.neutral,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (removed)
                          Text(
                            l10n.voiceCommentRemoved,
                            style: context.text.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: cs.textSecondary,
                            ),
                          )
                        else
                          CsLinkText(
                            c.body,
                            style: context.text.bodyMedium,
                            selectable: true,
                          ),
                        if (c.visibility == ContentVisibility.held && c.mine)
                          Padding(
                            padding: const EdgeInsets.only(top: CsSpace.xs),
                            child: Text(
                              l10n.voiceCommentUnderReview,
                              style: context.text.bodySmall?.copyWith(
                                color: cs.statusInProgress.fg,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: CsSpace.sm, top: 2),
                  child: Row(
                    children: [
                      // Wraps on narrow screens and in long languages.
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              agoText(context, c.createdAt, appNow()),
                              style: muted,
                            ),
                            if (!removed) ...[
                              _Link(
                                label: c.likeCount > 0
                                    ? '${l10n.reactLike} · ${countText(context, c.likeCount)}'
                                    : l10n.reactLike,
                                color: c.liked
                                    ? CsReactionStyle.color(context, 'like')
                                    : null,
                                semantics: l10n.campusLikeSemantics(
                                  c.likeCount,
                                ),
                                onTap: onReply == null
                                    ? null
                                    : () async => onResult(
                                        await cubit.likeComment(c.id),
                                      ),
                              ),
                              if (onReply != null)
                                _Link(label: l10n.campusReply, onTap: onReply),
                            ],
                          ],
                        ),
                      ),
                      if (!removed) ...[
                        IconButton(
                          tooltip: c.mine
                              ? l10n.deleteAction
                              : l10n.voiceReport,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: () => _menu(context),
                          icon: Icon(CsIcons.more, color: cs.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Like" / "Reply" under a comment.
class _Link extends StatelessWidget {
  const _Link({required this.label, this.onTap, this.color, this.semantics});

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: semantics != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CsRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.sm + 2,
          vertical: CsSpace.sm,
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: color ?? context.cs.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

/// The comment box: "Replying to …" when answering a comment; the mask
/// button switches anonymous / with my name.
class _Composer extends StatefulWidget {
  const _Composer({
    required this.focus,
    required this.kind,
    required this.onResult,
    required this.onCancelReply,
    required this.onSent,
    this.replyTo,
    this.replyName,
  });

  final FocusNode focus;
  final PostKind kind;
  final IssueComment? replyTo;
  final String? replyName;
  final VoidCallback onCancelReply;
  final VoidCallback onSent;
  final void Function(Failure?, [String?]) onResult;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _text = TextEditingController();
  bool _anonymous = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    final reply = widget.replyTo;
    final f = await context.read<IssueCubit>().addComment(
      body,
      anonymous: _anonymous,
      // Replies hang under the top comment of the thread.
      parentId: reply == null ? null : (reply.parentId ?? reply.id),
    );
    if (f == null) {
      _text.clear();
      widget.onSent();
    }
    widget.onResult(f);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final sending = context.select((IssueCubit c) => c.state.sending);
    final name = context.select((AuthBloc b) => b.state.user?.displayName);
    final who = _anonymous ? l10n.voiceAnonymous : (name ?? l10n.voiceYou);
    final hint = widget.replyTo != null
        ? l10n.campusReplyHint
        : widget.kind == PostKind.question
        ? l10n.campusAnswerHint
        : l10n.voiceCommentHint;
    return Material(
      color: cs.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.sm,
            CsSpace.xs,
            CsSpace.sm,
            CsSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: CsSpace.sm, bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.replyName != null
                            ? l10n.campusReplyingTo(widget.replyName!)
                            : l10n.voiceCommentAs(who),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: widget.replyName != null
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                    ),
                    if (widget.replyName != null)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .cancelButtonLabel,
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: widget.onCancelReply,
                        icon: const Icon(CsIcons.close),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: _anonymous
                        ? l10n.voiceCommentAnonymously
                        : l10n.voiceCommentWithName,
                    isSelected: _anonymous,
                    icon: const Icon(CsIcons.profile),
                    selectedIcon: const Icon(CsIcons.anonymousFill),
                    onPressed: () => setState(() => _anonymous = !_anonymous),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: widget.focus,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: hint,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.voiceSend,
                    onPressed: sending ? null : _send,
                    icon: sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(CsIcons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficialActions extends StatelessWidget {
  const _OfficialActions({required this.issue, required this.onResult});

  final Issue issue;
  final void Function(Failure?, [String?]) onResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<IssueCubit>();
    return Container(
      padding: const EdgeInsets.all(CsSpace.md),
      decoration: BoxDecoration(
        color: context.cs.primaryContainer,
        borderRadius: BorderRadius.circular(CsRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CsBadge(
            label: l10n.voiceOfficialBadge,
            icon: CsIcons.verifiedOutline,
          ),
          const SizedBox(height: CsSpace.sm),
          Wrap(
            spacing: CsSpace.sm,
            runSpacing: CsSpace.sm,
            children: [
              if (issue.can.changeStatus && issue.card.status.next.isNotEmpty)
                FilledButton.icon(
                  onPressed: () async {
                    final r = await showStatusSheet(context, issue.card.status);
                    if (r == null) return;
                    onResult(
                      await cubit.changeStatus(r.$1, r.$2),
                      l10n.voiceStatusUpdated,
                    );
                  },
                  icon: const Icon(CsIcons.changeStatus),
                  label: Text(l10n.voiceChangeStatus),
                ),
              if (issue.can.officialReply)
                OutlinedButton.icon(
                  onPressed: () async {
                    final body = await showTextSheet(
                      context,
                      title: l10n.voiceOfficialReply,
                      hint: l10n.voiceCommentHint,
                      subtitle: l10n.voiceOfficialReplyHint,
                      action: l10n.voiceSend,
                      maxLength: 2000,
                    );
                    if (body == null) return;
                    onResult(
                      await cubit.officialReply(body),
                      l10n.voiceReplyPosted,
                    );
                  },
                  icon: const Icon(CsIcons.raiseIssue),
                  label: Text(l10n.voiceOfficialReply),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: CsSpace.md),
    padding: const EdgeInsets.all(CsSpace.sm + 4),
    decoration: BoxDecoration(
      color: context.cs.statusInProgress.bg,
      borderRadius: BorderRadius.circular(CsRadius.md),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.cs.statusInProgress.fg),
        const SizedBox(width: CsSpace.sm),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: CsSpace.sm),
    child: Text(
      text.toUpperCase(),
      style: context.text.labelMedium?.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Edit the text and place (and an issue's title): the author, first 60
/// minutes.
Future<(String, String, String)?> _showEditSheet(
  BuildContext context,
  Issue issue,
) => showModalBottomSheet<(String, String, String)>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _EditSheet(issue: issue),
);

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.issue});

  final Issue issue;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _title = TextEditingController(text: widget.issue.card.title);
  late final _body = TextEditingController(text: widget.issue.body);
  late final _place = TextEditingController(
    text: widget.issue.card.locationLabel,
  );

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = widget.issue.card;
    final (min, max) = IssueDraft.bodyRange(card.kind);
    final n = _body.text.trim().runes.length;
    final ok =
        (!card.isIssue ||
            _title.text.trim().runes.length >= IssueDraft.minTitle) &&
        n >= min &&
        n <= max &&
        (n > 0 || card.imageCount > 0 || card.images.isNotEmpty);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.lg,
          0,
          CsSpace.lg,
          CsSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.isIssue ? l10n.voiceEditIssue : l10n.campusEditPost,
              style: context.text.titleLarge,
            ),
            Text(l10n.voiceEditWindow, style: context.text.bodySmall),
            const SizedBox(height: CsSpace.md),
            if (card.isIssue)
              TextField(
                controller: _title,
                maxLength: IssueDraft.maxTitle,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.voiceTitleLabel),
              ),
            TextField(
              controller: _body,
              maxLength: max,
              minLines: 3,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: card.isIssue
                    ? l10n.voiceBodyLabel
                    : l10n.campusTextLabel,
              ),
            ),
            TextField(
              controller: _place,
              maxLength: IssueDraft.maxLocation,
              decoration: InputDecoration(labelText: l10n.voicePlaceLabel),
            ),
            const SizedBox(height: CsSpace.sm),
            FilledButton(
              onPressed: ok
                  ? () => Navigator.of(context).pop((
                      card.isIssue ? _title.text : '',
                      _body.text,
                      _place.text,
                    ))
                  : null,
              child: Text(l10n.editAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a post (used by lists and pushes).
void openIssue(BuildContext context, String id) =>
    unawaited(context.push(Routes.campusIssue(id)));
