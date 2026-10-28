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
import '../../data/photo_picker.dart';
import '../../data/voice_cache.dart';
import '../bloc/raise_issue_cubit.dart';
import '../voice_format.dart';
import '../widgets/issue_list_card.dart';

/// Raise an issue: category → details and photos → review → post.
class RaiseIssuePage extends StatelessWidget {
  const RaiseIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => RaiseIssueCubit(
        getIt<VoiceRepository>(),
        getIt<VoiceCache>(),
        user?.id ?? '',
      )..start(),
      child: const _RaiseView(),
    );
  }
}

class _RaiseView extends StatelessWidget {
  const _RaiseView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RaiseIssueCubit>();
    final s = context.watch<RaiseIssueCubit>().state;
    return BlocListener<RaiseIssueCubit, RaiseState>(
      listenWhen: (a, b) =>
          (a.posted == null && b.posted != null) ||
          (b.failure != null && a.failure != b.failure),
      listener: (context, s) {
        final messenger = ScaffoldMessenger.of(context);
        if (s.posted != null) {
          final held = s.posted!.card.visibility != ContentVisibility.visible;
          messenger.showSnackBar(
            SnackBar(
              content: Text(held ? l10n.voicePostedHeld : l10n.voicePosted),
            ),
          );
          // Back to the feed (it reloads), then open the new issue.
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
      child: PopScope(
        canPop: s.step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) cubit.back();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.voiceNewTitle),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(bottom: CsSpace.sm),
                child: Column(
                  children: [
                    Text(
                      l10n.voiceStepOf(s.step + 1),
                      style: context.text.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: (s.step + 1) / 3),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: switch (s.step) {
              0 => const _CategoryStep(),
              1 => const _DetailsStep(),
              _ => const _ReviewStep(),
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RaiseIssueCubit>();
    final selected = context.select((RaiseIssueCubit c) => c.state.category);
    // Tapping picks (and shows the pick); Next continues, so a slip of the
    // finger never jumps ahead with the wrong category.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CsSpace.md),
            children: [
              Text(l10n.voiceStepCategory, style: context.text.titleLarge),
              const SizedBox(height: CsSpace.md),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: CsSpace.sm,
                crossAxisSpacing: CsSpace.sm,
                childAspectRatio: 0.95,
                children: [
                  for (final c in IssueCategory.values)
                    _CategoryTile(
                      category: c,
                      selected: selected == c,
                      onTap: () => cubit.pickCategory(c),
                    ),
                ],
              ),
              const SizedBox(height: CsSpace.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: context.cs.textSecondary,
                  ),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.voiceSafetyNote,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm,
              CsSpace.md,
              CsSpace.md,
            ),
            child: FilledButton(
              onPressed: selected == null ? null : cubit.toDetails,
              child: Text(l10n.voiceNext),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IssueCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: selected ? cs.primaryContainer : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.md),
        side: BorderSide(color: selected ? cs.primary : cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CsCategoryIcon(category: category.wire),
                  if (selected)
                    PositionedDirectional(
                      top: -6,
                      end: -10,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: CsSpace.sm),
              Text(
                categoryLabel(AppLocalizations.of(context), category),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsStep extends StatefulWidget {
  const _DetailsStep();

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  late final RaiseState _start = context.read<RaiseIssueCubit>().state;
  late final _title = TextEditingController(text: _start.title);
  late final _body = TextEditingController(text: _start.body);
  late final _place = TextEditingController(text: _start.place);
  bool _tried = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final camera = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.voiceFromGallery),
              onTap: () => Navigator.of(sheet).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.voiceTakePhoto),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (camera == null || !mounted) return;
    final cubit = context.read<RaiseIssueCubit>();
    final picked = await getIt<PhotoPicker>().pick(camera: camera);
    if (picked == null || !mounted) return;
    if (picked.bytes.length > 8 * 1024 * 1024) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorImageTooLarge)));
      return;
    }
    await cubit.addPhoto(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RaiseIssueCubit>();
    final s = context.watch<RaiseIssueCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(CsSpace.md),
      children: [
        Text(l10n.voiceStepDetails, style: context.text.titleLarge),
        const SizedBox(height: CsSpace.md),
        TextField(
          controller: _title,
          onChanged: cubit.setTitle,
          maxLength: IssueDraft.maxTitle,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.voiceTitleLabel,
            hintText: l10n.voiceTitleHint,
            errorText: _tried && !s.titleOk
                ? l10n.voiceAtLeast(IssueDraft.minTitle)
                : null,
          ),
        ),
        const SizedBox(height: CsSpace.sm),
        TextField(
          controller: _body,
          onChanged: cubit.setBody,
          maxLength: IssueDraft.maxBody,
          minLines: 4,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.voiceBodyLabel,
            hintText: l10n.voiceBodyHint,
            hintMaxLines: 3,
            alignLabelWithHint: true,
            errorText: _tried && !s.bodyOk
                ? l10n.voiceAtLeast(IssueDraft.minBody)
                : null,
          ),
        ),
        const SizedBox(height: CsSpace.sm),
        TextField(
          controller: _place,
          onChanged: cubit.setPlace,
          maxLength: IssueDraft.maxLocation,
          decoration: InputDecoration(
            labelText: l10n.voicePlaceLabel,
            hintText: l10n.voicePlaceHint,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: CsSpace.sm),
        Text(l10n.voicePhotosLabel, style: context.text.titleSmall),
        Text(l10n.voicePhotosHint, style: context.text.bodySmall),
        const SizedBox(height: CsSpace.sm),
        Wrap(
          spacing: CsSpace.sm,
          runSpacing: CsSpace.sm,
          children: [
            for (final (i, p) in s.photos.indexed)
              _PhotoThumb(
                photo: p,
                label: l10n.voicePhoto(i + 1),
                removeLabel: l10n.voiceRemovePhoto,
                onRemove: () => cubit.removePhoto(p.key),
              ),
            if (s.canAddPhoto)
              SizedBox(
                width: 84,
                height: 84,
                child: OutlinedButton(
                  onPressed: _addPhoto,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: Semantics(
                    label: l10n.voiceAddPhoto,
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: CsSpace.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: cubit.back,
                child: Text(l10n.voiceBack),
              ),
            ),
            const SizedBox(width: CsSpace.sm),
            Expanded(
              child: FilledButton(
                onPressed: s.uploading
                    ? null
                    : () {
                        setState(() => _tried = true);
                        unawaited(cubit.review());
                      },
                child: Text(s.uploading ? l10n.voiceUploading : l10n.voiceNext),
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
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
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
                              Icon(Icons.block, color: cs.onError, size: 20),
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
                      : Icon(Icons.error_outline, color: cs.onError),
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
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RaiseIssueCubit>();
    final s = context.watch<RaiseIssueCubit>().state;
    final similar = s.similar;
    return ListView(
      padding: const EdgeInsets.all(CsSpace.md),
      children: [
        Text(l10n.voiceStepReview, style: context.text.titleLarge),
        const SizedBox(height: CsSpace.md),
        Text(l10n.voiceSimilarTitle, style: context.text.titleSmall),
        const SizedBox(height: CsSpace.xs),
        if (similar == null)
          const Padding(
            padding: EdgeInsets.all(CsSpace.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (similar.isEmpty)
          Text(l10n.voiceNoSimilar, style: context.text.bodyMedium)
        else ...[
          Text(l10n.voiceSimilarHint, style: context.text.bodySmall),
          const SizedBox(height: CsSpace.sm),
          for (final card in similar) ...[
            IssueListCard(
              card: card,
              onTap: () => context.push(Routes.campusIssue(card.id)),
            ),
            if (!card.mine)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(top: CsSpace.xs),
                  child: CsMeTooButton(
                    label: l10n.voiceMeToo,
                    count: countText(context, card.meTooCount),
                    selected: card.voted,
                    onPressed: () async {
                      final f = await cubit.meTooSimilar(card);
                      if (f != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(voiceErrorText(context, f))),
                        );
                      }
                    },
                  ),
                ),
              ),
            const SizedBox(height: CsSpace.sm),
          ],
        ],
        const SizedBox(height: CsSpace.lg),
        CsAnonToggle(
          value: s.anonymous,
          onChanged: cubit.setAnonymous,
          title: l10n.voicePostAnon,
          subtitle: s.anonymous
              ? l10n.voicePostAnonHint
              : l10n.voicePostNamedHint,
          linkLabel: l10n.voiceHowAnonymity,
          onLink: () => context.push(Routes.campusAnonymity),
        ),
        if (s.category == IssueCategory.safety) ...[
          const SizedBox(height: CsSpace.sm),
          Text(l10n.voiceSafetyNote, style: context.text.bodySmall),
        ],
        const SizedBox(height: CsSpace.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: s.posting ? null : cubit.back,
                child: Text(l10n.voiceBack),
              ),
            ),
            const SizedBox(width: CsSpace.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: s.posting ? null : cubit.post,
                icon: s.posting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(s.anonymous ? Icons.masks : Icons.send),
                label: Text(l10n.voicePost),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
