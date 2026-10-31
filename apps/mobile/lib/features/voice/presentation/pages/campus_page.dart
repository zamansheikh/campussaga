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
import '../../data/voice_cache.dart';
import '../bloc/feed_cubit.dart';
import '../voice_format.dart';
import '../voice_updates.dart';
import '../widgets/feed_controls.dart';
import '../widgets/post_card.dart';

/// The Campus tab: the university's own social feed. Posts, questions,
/// polls and issues; For you · Latest · Ask · Issues.
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
  bool _searching = false;
  late final StreamSubscription<VoiceUpdate> _updates;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 800) {
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

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching && _search.text.isNotEmpty) {
      _search.clear();
      context.read<FeedCubit>().setQuery('');
    }
  }

  Future<void> _compose(PostKind kind, {bool photo = false}) async {
    final cubit = context.read<FeedCubit>();
    final posted = await context.push<IssueCard>(
      Routes.campusCompose(kind, photo: photo),
    );
    if (posted != null && mounted) unawaited(cubit.load());
  }

  void _snack(Failure? f) {
    if (f == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(voiceErrorText(context, f))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FeedCubit>();
    final s = context.watch<FeedCubit>().state;
    final user = context.select((AuthBloc b) => b.state.user);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.campusTitle),
        actions: [
          IconButton(
            tooltip: l10n.campusSearchHint,
            isSelected: _searching,
            icon: const Icon(CsIcons.search),
            selectedIcon: const Icon(CsIcons.close),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: l10n.voiceHowAnonymity,
            icon: const Icon(CsIcons.privacy),
            onPressed: () => context.push(Routes.campusAnonymity),
          ),
          IconButton(
            tooltip: l10n.campusMyPosts,
            icon: const Icon(CsIcons.myIssues),
            onPressed: () => context.push(Routes.campusMine),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // tabs keep several alive at once
        tooltip: l10n.campusNewPost,
        onPressed: () => _compose(PostKind.post),
        child: const Icon(CsIcons.add),
      ),
      body: RefreshIndicator(
        onRefresh: cubit.load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_searching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CsSpace.md,
                    CsSpace.sm,
                    CsSpace.md,
                    0,
                  ),
                  child: TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.campusSearchHint,
                      prefixIcon: const Icon(CsIcons.search),
                    ),
                  ),
                ),
              ),
            if (!_searching && user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CsSpace.md,
                    CsSpace.sm,
                    CsSpace.md,
                    0,
                  ),
                  child: CsComposerPrompt(
                    avatar: UserAvatar.of(user, size: 40),
                    hint: l10n.campusPrompt,
                    onTap: () => _compose(PostKind.post),
                    actions: [
                      CsComposerAction(
                        icon: CsIcons.gallery,
                        label: l10n.campusQuickPhoto,
                        color: CsCategoryStyle.color('it'),
                        onTap: () => _compose(PostKind.post, photo: true),
                      ),
                      CsComposerAction(
                        icon: CsIcons.question,
                        label: l10n.campusKindQuestion,
                        color: CsCategoryStyle.color('general'),
                        onTap: () => _compose(PostKind.question),
                      ),
                      CsComposerAction(
                        icon: CsIcons.poll,
                        label: l10n.campusKindPoll,
                        color: CsCategoryStyle.color('hostel'),
                        onTap: () => _compose(PostKind.poll),
                      ),
                      CsComposerAction(
                        icon: CsIcons.raiseIssue,
                        label: l10n.campusKindIssue,
                        color: CsCategoryStyle.color('food'),
                        onTap: () => _compose(PostKind.issue),
                      ),
                    ],
                  ),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: FeedTabsHeader(
                tab: s.tab,
                onTab: cubit.setTab,
                labels: {
                  FeedTab.forYou: l10n.campusTabForYou,
                  FeedTab.latest: l10n.campusTabLatest,
                  FeedTab.ask: l10n.campusTabAsk,
                  FeedTab.issues: l10n.campusTabIssues,
                },
                background: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            SliverToBoxAdapter(child: FeedTopics(staff: widget.staff)),
            if (s.offline)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CsSpace.md,
                    0,
                    CsSpace.md,
                    CsSpace.sm,
                  ),
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
    final cubit = context.read<FeedCubit>();
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
            onAction: cubit.load,
          ),
        ),
      ];
    }
    if (s.items.isEmpty) {
      final (title, hint, kind) = switch (s.tab) {
        _ when s.query.isNotEmpty => (l10n.campusEmptySearch, null, null),
        FeedTab.ask => (
          l10n.campusEmptyAsk,
          l10n.campusEmptyAskHint,
          PostKind.question,
        ),
        FeedTab.issues => (
          l10n.voiceEmptyFeed,
          l10n.voiceEmptyFeedHint,
          PostKind.issue,
        ),
        _ => (l10n.campusEmptyFeed, l10n.campusEmptyFeedHint, PostKind.post),
      };
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: CsEmptyState(
            icon: CsIcons.campus,
            title: title,
            message: hint,
            actionLabel: kind == null ? null : kindLabel(l10n, kind),
            onAction: kind == null ? null : () => _compose(kind),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
        sliver: SliverList.separated(
          itemCount: s.items.length + (s.loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: CsSpace.sm + 4),
          itemBuilder: (context, i) {
            if (i == s.items.length) {
              return const Padding(
                padding: EdgeInsets.all(CsSpace.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final card = s.items[i];
            void open({bool comment = false}) => unawaited(
              context.push(Routes.campusIssue(card.id, comment: comment)),
            );
            return PostCard(
              card: card,
              offline: s.offline,
              onOpen: open,
              onComment: () => open(comment: true),
              onReact: (r) async => _snack(await cubit.react(card.id, r)),
              onVote: (o) async => _snack(await cubit.votePoll(card.id, o)),
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
