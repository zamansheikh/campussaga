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
import '../../data/voice_cache.dart';
import '../bloc/feed_cubit.dart';
import '../voice_format.dart';
import '../voice_updates.dart';
import '../widgets/issue_list_card.dart';

/// The Campus tab: the university's issues.
class CampusPage extends StatelessWidget {
  const CampusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => FeedCubit(
        getIt<VoiceRepository>(),
        getIt<VoiceCache>(),
        user?.id ?? '',
      )..load(),
      child: _CampusView(staff: _isStaff(user)),
    );
  }
}

/// Officials and moderators also see private safety reports.
bool _isStaff(UserProfile? u) =>
    const {'authority', 'moderator', 'admin'}.contains(u?.role);

class _CampusView extends StatefulWidget {
  const _CampusView({required this.staff});

  final bool staff;

  @override
  State<_CampusView> createState() => _CampusViewState();
}

class _CampusViewState extends State<_CampusView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  late final StreamSubscription<VoiceUpdate> _updates;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        unawaited(context.read<FeedCubit>().loadMore());
      }
    });
    _updates = voiceUpdates.stream.listen((u) {
      if (!mounted) return;
      final feed = context.read<FeedCubit>();
      switch (u) {
        case IssueChanged(:final card):
          feed.updated(card);
        case IssueDeleted(:final id):
          feed.removed(id);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_updates.cancel());
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => context.read<FeedCubit>().setQuery(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FeedCubit>();
    final s = context.watch<FeedCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.voiceTitle),
        actions: [
          IconButton(
            tooltip: l10n.voiceHowAnonymity,
            icon: const Icon(CsIcons.privacy),
            onPressed: () => context.push(Routes.campusAnonymity),
          ),
          IconButton(
            tooltip: l10n.voiceMyIssues,
            icon: const Icon(CsIcons.myIssues),
            onPressed: () => context.push(Routes.campusMine),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null, // tabs keep several alive at once
        onPressed: () async {
          final posted = await context.push<IssueCard>(Routes.campusNew);
          if (posted != null && context.mounted) unawaited(cubit.load());
        },
        icon: const Icon(CsIcons.raiseIssue),
        label: Text(l10n.voiceRaiseIssue),
      ),
      body: RefreshIndicator(
        onRefresh: cubit.load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CsSpace.md,
                  CsSpace.sm,
                  CsSpace.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.voiceSearchHint,
                        prefixIcon: const Icon(CsIcons.search),
                      ),
                    ),
                    const SizedBox(height: CsSpace.sm),
                    SegmentedButton<IssueSort>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: IssueSort.trending,
                          label: Text(l10n.voiceSortTrending),
                        ),
                        ButtonSegment(
                          value: IssueSort.newest,
                          label: Text(l10n.voiceSortNew),
                        ),
                        ButtonSegment(
                          value: IssueSort.solved,
                          label: Text(l10n.voiceSortSolved),
                        ),
                      ],
                      selected: {s.sort},
                      onSelectionChanged: (v) => cubit.setSort(v.first),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CsSpace.md,
                    vertical: CsSpace.sm,
                  ),
                  children: [
                    if (widget.staff) ...[
                      FilterChip(
                        avatar: const Icon(CsIcons.lock, size: 18),
                        label: Text(l10n.voiceSafetyReports),
                        selected: s.safety,
                        onSelected: cubit.setSafety,
                      ),
                      const SizedBox(width: CsSpace.sm),
                    ],
                    ChoiceChip(
                      label: Text(l10n.voiceAllCategories),
                      selected: s.category == null,
                      showCheckmark: false,
                      onSelected: (_) => cubit.setCategory(null),
                    ),
                    for (final c in IssueCategory.values)
                      if (c != IssueCategory.safety) ...[
                        const SizedBox(width: CsSpace.sm),
                        ChoiceChip(
                          avatar: Icon(CsCategoryStyle.icon(c.wire), size: 18),
                          label: Text(categoryLabel(l10n, c)),
                          selected: s.category == c,
                          showCheckmark: false,
                          onSelected: (_) => cubit.setCategory(c),
                        ),
                      ],
                  ],
                ),
              ),
            ),
            if (s.offline)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
                  child: _OfflineNote(text: l10n.errorNetwork),
                ),
              ),
            ..._list(context, s),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context, FeedState s) {
    final l10n = AppLocalizations.of(context);
    if (s.status == FeedStatus.loading && s.items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (s.status == FeedStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: CsEmptyState(
            icon: CsIcons.offline,
            title: voiceErrorText(context, s.failure!),
            actionLabel: l10n.tryAgain,
            onAction: context.read<FeedCubit>().load,
          ),
        ),
      ];
    }
    if (s.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: CsEmptyState(
            icon: CsIcons.campus,
            title: s.query.isNotEmpty
                ? l10n.voiceEmptySearch
                : l10n.voiceEmptyFeed,
            message: s.query.isNotEmpty ? null : l10n.voiceEmptyFeedHint,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
        sliver: SliverList.separated(
          itemCount: s.items.length + (s.loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: CsSpace.sm),
          itemBuilder: (context, i) {
            if (i == s.items.length) {
              return const Padding(
                padding: EdgeInsets.all(CsSpace.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final card = s.items[i];
            return IssueListCard(
              card: card,
              onTap: () => context.push(Routes.campusIssue(card.id)),
            );
          },
        ),
      ),
    ];
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(CsSpace.sm),
    decoration: BoxDecoration(
      color: context.cs.surfaceVariant,
      borderRadius: BorderRadius.circular(CsRadius.sm),
    ),
    child: Row(
      children: [
        Icon(CsIcons.offline, size: 18, color: context.cs.textSecondary),
        const SizedBox(width: CsSpace.sm),
        Expanded(child: Text(text, style: context.text.bodySmall)),
      ],
    ),
  );
}
