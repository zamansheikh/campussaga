import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/clock.dart';
import '../../classes/presentation/bloc/my_classes_cubit.dart';
import '../../classes/presentation/class_format.dart';
import 'seen_cubit.dart';

enum _Action { edit, pin, unpin, delete }

/// The group's announcements on the group page. The CR posts, pins and
/// deletes here.
class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key, required this.group});

  final ClassGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final list = group.announcements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: CsSpace.xs),
                child: Text(
                  l10n.announcements.toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    letterSpacing: 0.8,
                    color: cs.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (group.isCr)
              TextButton.icon(
                onPressed: () => showComposer(context, group),
                icon: const Icon(CsIcons.raiseIssue, size: 20),
                label: Text(l10n.postAction),
              ),
          ],
        ),
        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(CsSpace.md),
              child: Text(
                group.isCr ? l10n.noAnnouncementsCr : l10n.noAnnouncements,
                style: context.text.bodyMedium?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ),
          )
        else
          for (final a in list)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.sm),
              child: AnnouncementCard(group: group, announcement: a),
            ),
      ],
    );
  }
}

/// One message: text, when, pinned; CR menu. With [maxLines] (Today) the
/// text is cut, and a tap opens it in place ("See more" / "Show less");
/// the group's name then leads to the group ([onOpenGroup]).
class AnnouncementCard extends StatefulWidget {
  const AnnouncementCard({
    super.key,
    required this.group,
    required this.announcement,
    this.showGroup = false,
    this.isNew = false,
    this.onOpenGroup,
    this.maxLines,
  });

  final ClassGroup group;
  final Announcement announcement;
  final bool showGroup;
  final bool isNew;
  final VoidCallback? onOpenGroup;
  final int? maxLines;

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _expanded = false;
  late final _groupTap = TapGestureRecognizer()
    ..onTap = () => widget.onOpenGroup?.call();

  @override
  void dispose() {
    _groupTap.dispose();
    super.dispose();
  }

  ClassGroup get group => widget.group;
  Announcement get announcement => widget.announcement;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) context.read<SeenCubit>().markRead(group, announcement);
  }

  Future<void> _act(BuildContext context, _Action action) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyClassesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    if (action == _Action.delete) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.deleteAnnouncementTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: dialog.cs.error),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.deleteAction),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    if (action == _Action.edit) {
      if (!context.mounted) return;
      await showComposer(context, group, editing: announcement);
      return;
    }
    try {
      switch (action) {
        case _Action.edit:
          break;
        case _Action.pin:
        case _Action.unpin:
          await cubit.setAnnouncementPinned(
            group.id,
            announcement.id,
            pinned: action == _Action.pin,
          );
        case _Action.delete:
          await cubit.deleteAnnouncement(group.id, announcement.id);
      }
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final a = announcement;
    final cut = widget.maxLines;
    final meta = [
      agoText(context, a.createdAt, appNow()),
      if (a.edited) l10n.editedLabel,
    ].join(' · ');
    final style = context.text.bodyLarge;
    return Card(
      color: a.pinned ? cs.primaryContainer.withValues(alpha: 0.45) : null,
      child: InkWell(
        onTap: cut == null ? null : _toggle,
        borderRadius: BorderRadius.circular(CsRadius.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, CsSpace.xs, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.pinned ? CsIcons.pin : CsIcons.raiseIssue,
                  size: 19,
                  color: cs.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              if (widget.showGroup) ...[
                                TextSpan(
                                  text: group.title,
                                  style: widget.onOpenGroup == null
                                      ? null
                                      : TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  recognizer: _groupTap,
                                ),
                                const TextSpan(text: ' · '),
                              ],
                              TextSpan(text: meta),
                            ],
                          ),
                          style: context.text.labelMedium,
                        ),
                        if (a.pinned) CsBadge(label: l10n.pinnedLabel),
                        if (widget.isNew)
                          CsBadge(
                            label: l10n.newBadge,
                            tone: CsBadgeTone.accent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (cut == null)
                      CsLinkText(a.body, style: style, selectable: true)
                    else
                      LayoutBuilder(
                        builder: (context, box) {
                          final painter = TextPainter(
                            text: TextSpan(text: a.body, style: style),
                            maxLines: cut,
                            textDirection: Directionality.of(context),
                            textScaler: MediaQuery.textScalerOf(context),
                          )..layout(maxWidth: box.maxWidth);
                          final long = painter.didExceedMaxLines;
                          painter.dispose();
                          return AnimatedSize(
                            duration: CsMotion.normal,
                            curve: CsMotion.curve,
                            alignment: Alignment.topCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CsLinkText(
                                  a.body,
                                  style: style,
                                  maxLines: _expanded ? null : cut,
                                  overflow: _expanded
                                      ? null
                                      : TextOverflow.ellipsis,
                                ),
                                if (long)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _expanded
                                          ? l10n.showLess
                                          : l10n.campusSeeMore,
                                      style: context.text.labelLarge?.copyWith(
                                        color: cs.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              // The CR can change it from Today too.
              if (group.isCr)
                PopupMenuButton<_Action>(
                  icon: const Icon(CsIcons.more),
                  onSelected: (x) => _act(context, x),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _Action.edit,
                      child: Text(l10n.editAction),
                    ),
                    if (a.pinned)
                      PopupMenuItem(
                        value: _Action.unpin,
                        child: Text(l10n.unpinAction),
                      )
                    else
                      PopupMenuItem(
                        value: _Action.pin,
                        child: Text(l10n.pinAction),
                      ),
                    PopupMenuItem(
                      value: _Action.delete,
                      child: Text(
                        l10n.deleteAction,
                        style: TextStyle(color: context.cs.error),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(width: CsSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// The CR writes a message (optionally pinned), or changes the text of
/// [editing].
Future<void> showComposer(
  BuildContext context,
  ClassGroup group, {
  Announcement? editing,
}) {
  final cubit = context.read<MyClassesCubit>();
  final seen = context.read<SeenCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: seen),
      ],
      child: _Composer(group: group, host: context, editing: editing),
    ),
  );
}

class _Composer extends StatefulWidget {
  const _Composer({required this.group, required this.host, this.editing});

  final ClassGroup group;
  final BuildContext host;
  final Announcement? editing;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late final _body = TextEditingController(text: widget.editing?.body);
  bool _pinned = false;
  bool _busy = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(widget.host);
    final cubit = context.read<MyClassesCubit>();
    final seen = context.read<SeenCubit>();
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final editing = widget.editing;
      if (editing != null) {
        await cubit.editAnnouncement(
          widget.group.id,
          editing.id,
          _body.text.trim(),
        );
      } else {
        await cubit.postAnnouncement(
          widget.group.id,
          _body.text.trim(),
          pinned: _pinned,
        );
        final g = cubit.state.group(widget.group.id);
        if (g != null) seen.markSeen(g); // your own post isn't "new" to you
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            editing != null ? l10n.announcementSaved : l10n.announcementPosted,
          ),
        ),
      );
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editing = widget.editing;
    final empty = _body.text.trim().isEmpty;
    // Editing: nothing to save until the text changes.
    final same = editing != null && _body.text.trim() == editing.body.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            0,
            CsSpace.lg,
            CsSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing != null ? l10n.editAnnouncement : l10n.newAnnouncement,
                style: context.text.titleMedium,
              ),
              Text(widget.group.title, style: context.text.bodySmall),
              const SizedBox(height: CsSpace.md),
              TextField(
                controller: _body,
                autofocus: true,
                enabled: !_busy,
                minLines: 3,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.announcementHint),
              ),
              if (editing == null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pinToTop),
                  subtitle: Text(l10n.pinToTopHint),
                  value: _pinned,
                  onChanged: _busy ? null : (v) => setState(() => _pinned = v),
                ),
              if (_failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: CsSpace.sm),
                  child: Text(
                    classErrorText(l10n, _failure!),
                    style: context.text.bodyMedium?.copyWith(
                      color: context.cs.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _busy || empty || same ? null : _post,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        editing != null ? CsIcons.checkCircle : CsIcons.send,
                      ),
                label: Text(
                  editing != null ? l10n.saveAction : l10n.postAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
