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
import '../widgets/voice_image.dart';
import '../widgets/voice_sheets.dart';

/// One issue: details, photos, status history, comments.
class IssuePage extends StatelessWidget {
  const IssuePage({super.key, required this.issueId});

  final String issueId;

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
      child: const _IssueView(),
    );
  }
}

class _IssueView extends StatefulWidget {
  const _IssueView();

  @override
  State<_IssueView> createState() => _IssueViewState();
}

class _IssueViewState extends State<_IssueView> {
  late final StreamSubscription<IssueCard> _cards;

  @override
  void initState() {
    super.initState();
    _cards = context.read<IssueCubit>().cards.listen(
      (c) => voiceUpdates.add(IssueChanged(c)),
    );
  }

  @override
  void dispose() {
    unawaited(_cards.cancel());
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
          title: l10n.voiceDeleteIssueTitle,
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
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (issue != null && !s.offline)
            PopupMenuButton<String>(
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
      ),
      body: switch (issue) {
        null when s.loading => const Center(child: CircularProgressIndicator()),
        null => CsEmptyState(
          icon: Icons.search_off_outlined,
          title: voiceErrorText(
            context,
            s.failure ?? const UnexpectedFailure(),
          ),
          actionLabel: l10n.tryAgain,
          onAction: context.read<IssueCubit>().load,
        ),
        final issue => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: context.read<IssueCubit>().load,
                child: _Body(issue: issue, state: s, onResult: _done),
              ),
            ),
            if (!s.offline &&
                issue.card.visibility != ContentVisibility.removed)
              _Composer(onResult: _done),
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
    required this.onResult,
  });

  final Issue issue;
  final IssueState state;
  final void Function(Failure?, [String?]) onResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final cubit = context.read<IssueCubit>();
    final c = issue.card;
    final now = appNow();
    return ListView(
      padding: const EdgeInsets.fromLTRB(CsSpace.md, 0, CsSpace.md, CsSpace.xl),
      children: [
        if (state.offline)
          _Note(icon: Icons.cloud_off_outlined, text: l10n.errorNetwork),
        ..._notices(l10n, issue),
        Row(
          children: [
            CsCategoryIcon(category: c.category.wire, size: 32),
            const SizedBox(width: CsSpace.sm),
            Expanded(
              child: Text(
                categoryLabel(l10n, c.category),
                style: context.text.labelLarge?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ),
            issueChip(l10n, c),
          ],
        ),
        const SizedBox(height: CsSpace.sm),
        Text(c.title, style: context.text.headlineSmall),
        const SizedBox(height: CsSpace.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: CsSpace.sm,
          runSpacing: CsSpace.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.anonymous ? Icons.masks_outlined : Icons.person_outline,
                  size: 16,
                  color: cs.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${issueAuthorLabel(l10n, c)} · ${agoText(context, c.createdAt, now)}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
            if (c.locationLabel.isNotEmpty)
              CsBadge(
                label: c.locationLabel,
                icon: Icons.place_outlined,
                tone: CsBadgeTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: CsSpace.md),
        SelectableText(issue.body, style: context.text.bodyLarge),
        if (issue.images.isNotEmpty) ...[
          const SizedBox(height: CsSpace.md),
          CsImageGrid(
            count: issue.images.length,
            builder: (_, i) => VoiceImage(issue.images[i].id),
            onTap: (i) => showPhotoViewer(context, issue.images, i),
            semanticLabel: (i) => l10n.voicePhoto(i + 1),
          ),
        ],
        const SizedBox(height: CsSpace.md),
        Wrap(
          spacing: CsSpace.sm,
          runSpacing: CsSpace.sm,
          children: [
            if (!c.mine)
              CsMeTooButton(
                label: l10n.voiceMeToo,
                count: countText(context, c.meTooCount),
                selected: c.voted,
                semanticLabel: l10n.voiceMeTooSemantics(c.meTooCount),
                onPressed: state.offline
                    ? null
                    : () async => onResult(await cubit.toggleMeToo()),
              )
            else
              CsBadge(
                label:
                    '${l10n.voiceMeToo} · ${countText(context, c.meTooCount)}',
                icon: Icons.front_hand_outlined,
                tone: CsBadgeTone.neutral,
              ),
            OutlinedButton.icon(
              onPressed: state.offline
                  ? null
                  : () async => onResult(await cubit.toggleFollow()),
              icon: Icon(
                c.following
                    ? Icons.notifications_active
                    : Icons.notifications_none,
              ),
              label: Text(c.following ? l10n.voiceFollowing : l10n.voiceFollow),
            ),
          ],
        ),
        if (issue.can.changeStatus || issue.can.officialReply) ...[
          const SizedBox(height: CsSpace.md),
          _OfficialActions(issue: issue, onResult: onResult),
        ],
        const SizedBox(height: CsSpace.lg),
        _Title(l10n.voiceStatusHistory),
        CsStatusTimeline(steps: _steps(context, issue)),
        const SizedBox(height: CsSpace.lg),
        _Title(
          '${l10n.voiceComments} · ${countText(context, state.comments.length)}',
        ),
        if (state.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CsSpace.md),
            child: Text(l10n.voiceNoComments, style: context.text.bodyMedium),
          ),
        for (final comment in state.comments)
          _CommentTile(comment: comment, onResult: onResult),
        if (state.commentsCursor != null)
          Center(
            child: TextButton(
              onPressed: state.loadingMore ? null : cubit.loadMoreComments,
              child: Text(l10n.voiceLoadMore),
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
          icon: Icons.delete_outline,
          text: issue.removedReason.isEmpty
              ? l10n.voiceRemovedByYou
              : l10n.voiceRemovedNotice(issue.removedReason),
        ),
      if (c.visibility == ContentVisibility.held)
        _Note(
          icon: Icons.hourglass_top,
          text: [
            l10n.voiceHeldNotice,
            holdReasonText(l10n, issue.holdReason),
          ].where((t) => t.isNotEmpty).join(' '),
        ),
      if (c.visibility == ContentVisibility.hidden)
        _Note(
          icon: Icons.visibility_off_outlined,
          text: issue.holdReason == 'moderator'
              ? l10n.voiceHeldModerator
              : l10n.voiceHiddenNotice,
        ),
      if (c.private)
        _Note(icon: Icons.lock_outline, text: l10n.voicePrivateNotice),
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
            icon: Icons.verified_outlined,
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
                  icon: const Icon(Icons.swap_horiz),
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
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(l10n.voiceOfficialReply),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onResult});

  final IssueComment comment;
  final void Function(Failure?, [String?]) onResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final c = comment;
    final cubit = context.read<IssueCubit>();
    final removed = c.visibility == ContentVisibility.removed;
    final official = c.official;
    final avatar = official
        ? Icons.verified
        : c.author != null
        ? Icons.person
        : Icons.masks;
    return Container(
      margin: const EdgeInsets.only(bottom: CsSpace.sm),
      padding: const EdgeInsets.all(CsSpace.sm + 4),
      decoration: BoxDecoration(
        color: official ? cs.primaryContainer : cs.surface,
        border: Border.all(color: official ? cs.primary : cs.border),
        borderRadius: BorderRadius.circular(CsRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: official ? cs.primary : cs.surfaceVariant,
                child: Icon(
                  avatar,
                  size: 16,
                  color: official ? cs.onPrimary : cs.textSecondary,
                ),
              ),
              const SizedBox(width: CsSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          commentWho(l10n, c),
                          style: context.text.titleSmall,
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
                    Text(
                      [
                        if (official && c.officialTitle.isNotEmpty)
                          c.officialTitle,
                        agoText(context, c.createdAt, appNow()),
                      ].join(' · '),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!removed)
                PopupMenuButton<String>(
                  iconSize: 20,
                  onSelected: (a) async {
                    if (a == 'delete') {
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
                  },
                  itemBuilder: (_) => [
                    if (c.mine)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.deleteAction),
                      )
                    else
                      PopupMenuItem(
                        value: 'report',
                        child: Text(l10n.voiceReport),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: CsSpace.sm),
          if (removed)
            Text(
              l10n.voiceCommentRemoved,
              style: context.text.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: cs.textSecondary,
              ),
            )
          else
            SelectableText(c.body, style: context.text.bodyMedium),
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
    );
  }
}

/// The comment box. The mask button switches anonymous / with my name.
class _Composer extends StatefulWidget {
  const _Composer({required this.onResult});

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
    final f = await context.read<IssueCubit>().addComment(
      body,
      anonymous: _anonymous,
    );
    if (f == null) _text.clear();
    widget.onResult(f);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final sending = context.select((IssueCubit c) => c.state.sending);
    final name = context.select((AuthBloc b) => b.state.user?.displayName);
    final who = _anonymous ? l10n.voiceAnonymous : (name ?? l10n.voiceYou);
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
                child: Text(
                  l10n.voiceCommentAs(who),
                  style: context.text.bodySmall,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: _anonymous
                        ? l10n.voiceCommentAnonymously
                        : l10n.voiceCommentWithName,
                    isSelected: _anonymous,
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.masks),
                    onPressed: () => setState(() => _anonymous = !_anonymous),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.voiceCommentHint,
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
                        : const Icon(Icons.send),
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

/// Edit title, details and place (author, first 60 minutes).
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
    final ok =
        _title.text.trim().length >= IssueDraft.minTitle &&
        _body.text.trim().length >= IssueDraft.minBody;
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
            Text(l10n.voiceEditIssue, style: context.text.titleLarge),
            Text(l10n.voiceEditWindow, style: context.text.bodySmall),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _title,
              maxLength: IssueDraft.maxTitle,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.voiceTitleLabel),
            ),
            TextField(
              controller: _body,
              maxLength: IssueDraft.maxBody,
              minLines: 3,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.voiceBodyLabel),
            ),
            TextField(
              controller: _place,
              maxLength: IssueDraft.maxLocation,
              decoration: InputDecoration(labelText: l10n.voicePlaceLabel),
            ),
            const SizedBox(height: CsSpace.sm),
            FilledButton(
              onPressed: ok
                  ? () =>
                        Navigator.of(context)
                            .pop((_title.text, _body.text, _place.text))
                  : null,
              child: Text(l10n.editAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens an issue (used by lists and pushes).
void openIssue(BuildContext context, String id) =>
    unawaited(context.push(Routes.campusIssue(id)));
