import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../data/photo_picker.dart';
import '../../data/voice_cache.dart';
import '../bloc/compose_cubit.dart';
import '../voice_format.dart';
import '../widgets/post_card.dart';

/// Write anything for Campus on one screen: a post, a question, a poll or
/// an issue. Anonymous unless the student chooses their name.
class ComposePage extends StatelessWidget {
  const ComposePage({
    super.key,
    this.kind = PostKind.post,
    this.pickPhoto = false,
  });

  final PostKind kind;

  /// Open the photo picker straight away (the feed's Photo button).
  final bool pickPhoto;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => ComposeCubit(
        getIt<VoiceRepository>(),
        getIt<VoiceCache>(),
        user?.id ?? '',
        kind: kind,
      )..start(),
      child: _ComposeView(pickPhoto: pickPhoto),
    );
  }
}

class _ComposeView extends StatefulWidget {
  const _ComposeView({required this.pickPhoto});

  final bool pickPhoto;

  @override
  State<_ComposeView> createState() => _ComposeViewState();
}

class _ComposeViewState extends State<_ComposeView> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _place = TextEditingController();
  final _options = <TextEditingController>[];
  bool _showPlace = false;

  @override
  void initState() {
    super.initState();
    _syncOptions(context.read<ComposeCubit>().state.pollOptions);
    if (widget.pickPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addPhoto());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _place.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  /// Keeps one text box per poll answer.
  void _syncOptions(List<String> options) {
    while (_options.length > options.length) {
      _options.removeLast().dispose();
    }
    for (var i = 0; i < options.length; i++) {
      if (i < _options.length) {
        if (_options[i].text != options[i]) _options[i].text = options[i];
      } else {
        _options.add(TextEditingController(text: options[i]));
      }
    }
  }

  /// A saved draft came back: show its text.
  void _restore(ComposeState s) {
    _title.text = s.title;
    _body.text = s.body;
    _place.text = s.place;
    _showPlace = s.place.isNotEmpty;
    _syncOptions(s.pollOptions);
    setState(() {});
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ComposeCubit>();
    if (!cubit.state.canAddPhoto) return;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CsIcons.gallery),
              title: Text(l10n.voiceFromGallery),
              onTap: () => Navigator.of(sheet).pop(false),
            ),
            ListTile(
              leading: const Icon(CsIcons.camera),
              title: Text(l10n.voiceTakePhoto),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (camera == null || !mounted) return;
    final picked = await getIt<PhotoPicker>().pick(camera: camera);
    if (picked == null || !mounted) return;
    if (picked.bytes.length > 8 * 1024 * 1024) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorImageTooLarge)));
      return;
    }
    await cubit.addPhoto(picked);
  }

  String _hint(AppLocalizations l10n, PostKind kind) => switch (kind) {
    PostKind.post => l10n.campusPostHint,
    PostKind.question => l10n.campusQuestionHint,
    PostKind.poll => l10n.campusPollHint,
    PostKind.issue => l10n.voiceBodyHint,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ComposeCubit>();
    final s = context.watch<ComposeCubit>().state;
    final user = context.select((AuthBloc b) => b.state.user);
    final (_, maxBody) = IssueDraft.bodyRange(s.kind);
    return MultiBlocListener(
      listeners: [
        BlocListener<ComposeCubit, ComposeState>(
          listenWhen: (a, b) => !a.restored && b.restored,
          listener: (_, s) => _restore(s),
        ),
        BlocListener<ComposeCubit, ComposeState>(
          listenWhen: (a, b) => a.pollOptions.length != b.pollOptions.length,
          listener: (_, s) => setState(() => _syncOptions(s.pollOptions)),
        ),
        BlocListener<ComposeCubit, ComposeState>(
          listenWhen: (a, b) =>
              (a.posted == null && b.posted != null) ||
              (b.failure != null && a.failure != b.failure),
          listener: (context, s) {
            final messenger = ScaffoldMessenger.of(context);
            if (s.posted != null) {
              final held =
                  s.posted!.card.visibility != ContentVisibility.visible;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(held ? l10n.voicePostedHeld : l10n.voicePosted),
                ),
              );
              // Back to the feed (it reloads), then open the new post.
              final router = GoRouter.of(context)..pop(s.posted!.card);
              unawaited(router.push(Routes.campusIssue(s.posted!.id)));
            } else if (s.failure != null) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    s.failure is NetworkFailure
                        ? '${l10n.voiceOfflineAction} ${l10n.voiceDraftKept}'
                        : voiceErrorText(context, s.failure!),
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(CsIcons.close),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.campusCreateTitle),
          actions: [
            CsBarButton(
              label: s.uploading ? l10n.voiceUploading : l10n.campusPostAction,
              busy: s.posting,
              onPressed: s.canPost ? cubit.post : null,
            ),
          ],
        ),
        body: SafeArea(
          // Short enough to build at once (no lazy list).
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm,
              CsSpace.md,
              CsSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Who(
                  anonymous: s.anonymous,
                  avatar: s.anonymous || user == null
                      ? CsAnonAvatar(seed: user?.id ?? 'me', size: 44)
                      : UserAvatar.of(user, size: 44),
                  name: s.anonymous
                      ? l10n.voiceAnonymous
                      : (user?.displayName ?? l10n.voiceYou),
                  onChanged: cubit.setAnonymous,
                ),
                const SizedBox(height: CsSpace.md),
                _KindPicker(kind: s.kind, onChanged: cubit.setKind),
                const SizedBox(height: CsSpace.md),
                if (s.kind == PostKind.issue) ...[
                  Text(l10n.campusIssueNote, style: context.text.bodySmall),
                  const SizedBox(height: CsSpace.md),
                  _Topics(
                    topics: IssueCategory.forIssues,
                    selected: s.category,
                    onSelected: cubit.setCategory,
                  ),
                  if (s.category == IssueCategory.safety)
                    Padding(
                      padding: const EdgeInsets.only(top: CsSpace.sm),
                      child: Text(
                        l10n.voiceSafetyNote,
                        style: context.text.bodySmall,
                      ),
                    ),
                  const SizedBox(height: CsSpace.md),
                  TextField(
                    controller: _title,
                    maxLength: IssueDraft.maxTitle,
                    onChanged: cubit.setTitle,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.voiceTitleLabel,
                      hintText: l10n.voiceTitleHint,
                      helperText: s.title.isNotEmpty && !s.titleOk
                          ? l10n.voiceAtLeast(IssueDraft.minTitle)
                          : null,
                    ),
                  ),
                  const SizedBox(height: CsSpace.sm),
                ],
                TextField(
                  controller: _body,
                  onChanged: cubit.setBody,
                  autofocus: !widget.pickPhoto && s.kind != PostKind.issue,
                  minLines: s.kind == PostKind.poll ? 2 : 5,
                  maxLines: null,
                  maxLength: maxBody,
                  textCapitalization: TextCapitalization.sentences,
                  style: s.kind == PostKind.issue
                      ? context.text.bodyLarge
                      : context.text.titleMedium,
                  decoration: InputDecoration(
                    hintText: _hint(l10n, s.kind),
                    labelText: s.kind == PostKind.issue
                        ? l10n.voiceBodyLabel
                        : null,
                    helperText: _bodyHelp(l10n, s),
                    border: s.kind == PostKind.issue ? null : InputBorder.none,
                    enabledBorder: s.kind == PostKind.issue
                        ? null
                        : InputBorder.none,
                    focusedBorder: s.kind == PostKind.issue
                        ? null
                        : InputBorder.none,
                    filled: s.kind == PostKind.issue ? null : false,
                    contentPadding: s.kind == PostKind.issue
                        ? null
                        : EdgeInsets.zero,
                  ),
                ),
                if (s.kind == PostKind.poll) ...[
                  const SizedBox(height: CsSpace.sm),
                  _PollEditor(
                    controllers: _options,
                    days: s.pollDays,
                    error:
                        s.typedOptions.length >= IssueDraft.minPollOptions &&
                            !s.optionsOk
                        ? l10n.campusPollNeedsOptions
                        : null,
                  ),
                ],
                const SizedBox(height: CsSpace.md),
                _Photos(onAdd: _addPhoto),
                if (s.kind != PostKind.issue) ...[
                  const SizedBox(height: CsSpace.md),
                  Text(l10n.campusTopic, style: context.text.titleSmall),
                  const SizedBox(height: CsSpace.sm),
                  _Topics(
                    topics: IssueCategory.forPosts,
                    selected: s.category,
                    onSelected: cubit.setCategory,
                  ),
                  const SizedBox(height: CsSpace.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      s.campusOnly ? CsIcons.lock : CsIcons.visitCampus,
                    ),
                    title: Text(l10n.campusOnlyLabel),
                    subtitle: Text(
                      s.campusOnly ? l10n.campusOnlyOn : l10n.campusOnlyOff,
                    ),
                    value: s.campusOnly,
                    onChanged: cubit.setCampusOnly,
                  ),
                ],
                const SizedBox(height: CsSpace.md),
                if (_showPlace || s.kind == PostKind.issue)
                  TextField(
                    controller: _place,
                    maxLength: IssueDraft.maxLocation,
                    onChanged: cubit.setPlace,
                    decoration: InputDecoration(
                      labelText: l10n.voicePlaceLabel,
                      hintText: l10n.voicePlaceHint,
                      prefixIcon: const Icon(CsIcons.place),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(CsIcons.placeAdd, size: 18),
                      label: Text(l10n.voicePlaceLabel),
                      onPressed: () => setState(() => _showPlace = true),
                    ),
                  ),
                if (s.kind == PostKind.issue && s.similar.isNotEmpty) ...[
                  const SizedBox(height: CsSpace.lg),
                  _Similar(similar: s.similar),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _bodyHelp(AppLocalizations l10n, ComposeState s) {
    if (s.body.trim().isEmpty) return null;
    if (s.bodyOk) return null;
    return switch (s.kind) {
      PostKind.question => l10n.campusQuestionTooShort,
      PostKind.issue => l10n.voiceAtLeast(IssueDraft.minBody),
      PostKind.poll => l10n.voiceAtLeast(IssueDraft.minPollQuestion),
      PostKind.post => null,
    };
  }
}

/// "Posting as Anonymous ▾": who the post shows, switched with a tap.
class _Who extends StatelessWidget {
  const _Who({
    required this.anonymous,
    required this.avatar,
    required this.name,
    required this.onChanged,
  });

  final bool anonymous;
  final Widget avatar;
  final String name;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Row(
      children: [
        avatar,
        const SizedBox(width: CsSpace.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.campusPostingAs, style: context.text.bodySmall),
              const SizedBox(height: 2),
              PopupMenuButton<bool>(
                initialValue: anonymous,
                onSelected: onChanged,
                tooltip: l10n.campusPostingAs,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: true,
                    child: ListTile(
                      leading: const Icon(CsIcons.anonymous),
                      title: Text(l10n.voiceAnonymous),
                      subtitle: Text(l10n.voicePostAnonHint),
                    ),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: ListTile(
                      leading: const Icon(CsIcons.profile),
                      title: Text(l10n.voiceYou),
                      subtitle: Text(l10n.voicePostNamedHint),
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CsSpace.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(CsRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        anonymous ? CsIcons.anonymous : CsIcons.profile,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.voiceHowAnonymity,
          icon: const Icon(CsIcons.privacy),
          onPressed: () => context.push(Routes.campusAnonymity),
        ),
      ],
    );
  }
}

/// Post · Ask · Poll · Issue.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.kind, required this.onChanged});

  final PostKind kind;
  final ValueChanged<PostKind> onChanged;

  static const _order = [
    PostKind.post,
    PostKind.question,
    PostKind.poll,
    PostKind.issue,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: CsSpace.sm,
      runSpacing: CsSpace.sm,
      children: [
        for (final k in _order)
          ChoiceChip(
            avatar: Icon(kindIcon(k), size: 18),
            label: Text(kindLabel(l10n, k)),
            selected: k == kind,
            showCheckmark: false,
            onSelected: (_) => onChanged(k),
          ),
      ],
    );
  }
}

class _Topics extends StatelessWidget {
  const _Topics({
    required this.topics,
    required this.selected,
    required this.onSelected,
  });

  final List<IssueCategory> topics;
  final IssueCategory? selected;
  final ValueChanged<IssueCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: CsSpace.sm,
      runSpacing: CsSpace.sm,
      children: [
        for (final c in topics)
          ChoiceChip(
            avatar: Icon(
              CsCategoryStyle.icon(c.wire),
              size: 18,
              color: CsCategoryStyle.color(c.wire),
            ),
            label: Text(categoryLabel(l10n, c)),
            selected: c == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(c),
          ),
      ],
    );
  }
}

/// The poll's answers (2–4) and how long it runs.
class _PollEditor extends StatelessWidget {
  const _PollEditor({
    required this.controllers,
    required this.days,
    this.error,
  });

  final List<TextEditingController> controllers;
  final int days;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ComposeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.sm),
            child: TextField(
              controller: controllers[i],
              maxLength: IssueDraft.maxPollOption,
              onChanged: (v) => cubit.setOption(i, v),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.campusPollOption(i + 1),
                counterText: '',
                suffixIcon: controllers.length > IssueDraft.minPollOptions
                    ? IconButton(
                        tooltip: l10n.deleteAction,
                        icon: const Icon(CsIcons.close, size: 18),
                        onPressed: () => cubit.removeOption(i),
                      )
                    : null,
              ),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.sm),
            child: Text(
              error!,
              style: context.text.bodySmall?.copyWith(color: context.cs.error),
            ),
          ),
        if (controllers.length < IssueDraft.maxPollOptions)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: cubit.addOption,
              icon: const Icon(CsIcons.add),
              label: Text(l10n.campusPollAddOption),
            ),
          ),
        const SizedBox(height: CsSpace.sm),
        Text(l10n.campusPollLength, style: context.text.titleSmall),
        const SizedBox(height: CsSpace.sm),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final d in IssueDraft.pollDayChoices)
              ButtonSegment(value: d, label: Text(l10n.campusPollDays(d))),
          ],
          selected: {days},
          onSelectionChanged: (v) => cubit.setPollDays(v.first),
        ),
      ],
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ComposeCubit>();
    final s = context.watch<ComposeCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voicePhotosLabel, style: context.text.titleSmall),
        Text(l10n.voicePhotosHint, style: context.text.bodySmall),
        const SizedBox(height: CsSpace.sm),
        Wrap(
          spacing: CsSpace.sm,
          runSpacing: CsSpace.sm,
          children: [
            for (var i = 0; i < s.photos.length; i++)
              _PhotoThumb(
                photo: s.photos[i],
                label: l10n.voicePhoto(i + 1),
                removeLabel: l10n.voiceRemovePhoto,
                onRemove: () => cubit.removePhoto(s.photos[i].key),
              ),
            if (s.canAddPhoto)
              Semantics(
                button: true,
                label: l10n.voiceAddPhoto,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(CsRadius.sm),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: context.cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(CsRadius.sm),
                      border: Border.all(color: context.cs.border),
                    ),
                    child: Icon(CsIcons.addPhoto, color: context.cs.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.photo,
    required this.label,
    required this.removeLabel,
    required this.onRemove,
  });

  final DraftPhoto photo;
  final String label;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Semantics(
      label: label,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(CsRadius.sm),
              child: Image.memory(photo.bytes, fit: BoxFit.cover),
            ),
            if (photo.uploading)
              ClipRRect(
                borderRadius: BorderRadius.circular(CsRadius.sm),
                child: ColoredBox(
                  color: cs.background.withValues(alpha: 0.5),
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
            if (photo.failure != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(CsRadius.sm),
                child: ColoredBox(
                  color: cs.error.withValues(alpha: 0.75),
                  child: photo.failure!.code == 'PHOTO_NOT_ALLOWED'
                      ? Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CsIcons.blocked,
                                color: cs.onError,
                                size: 20,
                              ),
                              Text(
                                AppLocalizations.of(context).voicePhotoRefused,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: context.text.labelSmall?.copyWith(
                                  color: cs.onError,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Icon(CsIcons.error, color: cs.onError),
                ),
              ),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton.filledTonal(
                tooltip: removeLabel,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: onRemove,
                icon: const Icon(CsIcons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Issues: the same problem raised before. Me too there instead.
class _Similar extends StatelessWidget {
  const _Similar({required this.similar});

  final List<IssueCard> similar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ComposeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.voiceSimilarTitle, style: context.text.titleSmall),
        Text(l10n.voiceSimilarHint, style: context.text.bodySmall),
        const SizedBox(height: CsSpace.sm),
        for (final c in similar)
          Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.sm),
            child: PostCard(
              card: c,
              onOpen: () => context.push(Routes.campusIssue(c.id)),
              onComment: () =>
                  context.push(Routes.campusIssue(c.id, comment: true)),
              onReact: (_) async {
                final f = await cubit.meTooSimilar(c);
                if (f != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(voiceErrorText(context, f))),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
