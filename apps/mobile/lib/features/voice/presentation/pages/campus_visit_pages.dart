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
import '../widgets/feed_controls.dart';
import '../widgets/post_card.dart';

/// Other universities to look around: a search and the most active ones.
class VisitCampusesPage extends StatefulWidget {
  const VisitCampusesPage({super.key});

  @override
  State<VisitCampusesPage> createState() => _VisitCampusesPageState();
}

class _VisitCampusesPageState extends State<VisitCampusesPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<CampusSummary> _items = const [];
  String? _cursor;
  bool _loading = true;
  bool _more = false;
  Failure? _failure;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) unawaited(_loadMore());
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final page = await getIt<VoiceRepository>().campuses(query: _search.text);
      if (!mounted || request != _request) return;
      setState(() {
        _items = page.items;
        _cursor = page.nextCursor;
        _loading = false;
      });
    } on Failure catch (f) {
      if (mounted && request == _request) {
        setState(() {
          _failure = f;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _more || _loading) return;
    final request = _request;
    setState(() => _more = true);
    try {
      final page = await getIt<VoiceRepository>().campuses(
        query: _search.text,
        cursor: cursor,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _items = [..._items, ...page.items];
        _cursor = page.nextCursor;
      });
    } on Failure {
      // Keep what's shown.
    } finally {
      if (mounted) setState(() => _more = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.visitCampusTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            CsSpace.sm,
            CsSpace.screen,
            CsSpace.xl,
          ),
          children: [
            TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.visitSearchHint,
                prefixIcon: const Icon(CsIcons.search),
              ),
            ),
            const SizedBox(height: CsSpace.lg),
            if (_search.text.trim().isEmpty)
              CsSectionTitle(title: l10n.visitMostActive),
            if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(CsSpace.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failure != null && _items.isEmpty)
              CsEmptyState(
                icon: CsIcons.offline,
                title: voiceErrorText(context, _failure!),
                actionLabel: l10n.tryAgain,
                onAction: _load,
              )
            else if (_items.isEmpty)
              CsEmptyState(
                icon: CsIcons.searchEmpty,
                title: l10n.visitNoCampuses,
              )
            else
              for (final c in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: CsSpace.sm),
                  child: _CampusTile(
                    campus: c,
                    onTap: () => context.push(Routes.campusOf(c.slug)),
                  ),
                ),
            if (_more)
              const Padding(
                padding: EdgeInsets.all(CsSpace.md),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

String _kindText(AppLocalizations l10n, String kind) => switch (kind) {
  'public' => l10n.visitPublic,
  'private' => l10n.visitPrivate,
  _ => '',
};

/// The name in the app's language: Bangla when there is one.
String _campusName(BuildContext context, CampusSummary c) =>
    Localizations.localeOf(context).languageCode == 'bn' && c.nameBn.isNotEmpty
    ? c.nameBn
    : c.name;

class _CampusTile extends StatelessWidget {
  const _CampusTile({required this.campus, required this.onTap});

  final CampusSummary campus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final c = campus;
    final line = [
      if (c.city.isNotEmpty) c.city,
      _kindText(l10n, c.kind),
      if (c.students > 0) l10n.visitStudents(c.students),
    ].where((x) => x.isNotEmpty).join(' · ');
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Row(
            children: [
              CampusMark(campus: c, size: 46),
              const SizedBox(width: CsSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _campusName(context, c),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (line.isNotEmpty)
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                    if (c.posts7d > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          l10n.visitPostsWeek(c.posts7d),
                          style: context.text.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(CsIcons.chevronRight, color: cs.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// One university, visited: its profile and what its students post
/// (read and react; only its students comment).
class CampusVisitPage extends StatefulWidget {
  const CampusVisitPage({super.key, required this.slug});

  final String slug;

  @override
  State<CampusVisitPage> createState() => _CampusVisitPageState();
}

class _CampusVisitPageState extends State<CampusVisitPage> {
  CampusProfile? _profile;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    try {
      final p = await getIt<VoiceRepository>().campus(widget.slug);
      if (mounted) setState(() => _profile = p);
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _profile;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _failure == null
            ? const Center(child: CircularProgressIndicator())
            : CsEmptyState(
                icon: CsIcons.visitCampus,
                title: voiceErrorText(context, _failure!),
                actionLabel: l10n.tryAgain,
                onAction: _load,
              ),
      );
    }
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => FeedCubit(
        getIt<VoiceRepository>(),
        getIt<VoiceCache>(),
        user?.id ?? '',
        universityId: p.summary.id,
      )..load(),
      child: _VisitView(profile: p, onRefreshProfile: _load),
    );
  }
}

class _VisitView extends StatefulWidget {
  const _VisitView({required this.profile, required this.onRefreshProfile});

  final CampusProfile profile;
  final Future<void> Function() onRefreshProfile;

  @override
  State<_VisitView> createState() => _VisitViewState();
}

class _VisitViewState extends State<_VisitView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 800) {
        unawaited(context.read<FeedCubit>().loadMore());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
    final p = widget.profile;
    final c = p.summary;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _campusName(context, c),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([cubit.load(), widget.onRefreshProfile()]);
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(profile: p)),
            SliverPersistentHeader(
              pinned: true,
              delegate: FeedTabsHeader(
                tab: s.tab,
                onTab: cubit.setTab,
                labels: {
                  FeedTab.forYou: l10n.campusTabForYou,
                  FeedTab.latest: l10n.campusTabLatest,
                  FeedTab.ask: l10n.campusTabAsk,
                },
                background: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            const SliverToBoxAdapter(child: FeedTopics()),
            if (s.status == FeedStatus.loading && s.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (s.status == FeedStatus.failure)
              SliverFillRemaining(
                hasScrollBody: false,
                child: CsEmptyState(
                  icon: CsIcons.offline,
                  title: voiceErrorText(context, s.failure!),
                  actionLabel: l10n.tryAgain,
                  onAction: cubit.load,
                ),
              )
            else if (s.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: CsEmptyState(
                  icon: CsIcons.campus,
                  title: l10n.visitEmpty,
                  message: l10n.visitEmptyHint,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
                sliver: SliverList.separated(
                  itemCount: s.items.length + (s.loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: CsSpace.sm + 4),
                  itemBuilder: (context, i) {
                    if (i == s.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(CsSpace.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final card = s.items[i];
                    void open() =>
                        unawaited(context.push(Routes.campusIssue(card.id)));
                    return PostCard(
                      card: card,
                      onOpen: open,
                      onComment: open,
                      onReact: (r) async =>
                          _snack(await cubit.react(card.id, r)),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: CsSpace.xl)),
          ],
        ),
      ),
    );
  }
}

/// Name, city and kind, website, and the numbers.
class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final CampusProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final c = profile.summary;
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final other = bangla ? c.name : c.nameBn;
    final kind = _kindText(l10n, c.kind);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CsSpace.md, CsSpace.sm, CsSpace.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CampusMark(campus: c, size: 56),
              const SizedBox(width: CsSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _campusName(context, c),
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (other.isNotEmpty && other != _campusName(context, c))
                      Text(other, style: context.text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.md),
          // One pill size for facts and the website link.
          Wrap(
            spacing: CsSpace.sm,
            runSpacing: CsSpace.sm,
            children: [
              if (profile.mine)
                CsPill(
                  label: l10n.visitYourCampus,
                  icon: CsIcons.verified,
                  highlight: true,
                ),
              if (c.city.isNotEmpty) CsPill(label: c.city, icon: CsIcons.place),
              if (kind.isNotEmpty)
                CsPill(label: kind, icon: CsIcons.university),
              if (profile.website.isNotEmpty)
                CsPill(
                  label: l10n.visitWebsite,
                  icon: CsIcons.visitCampus,
                  onTap: () => CsLinkText.onOpen?.call(
                    context,
                    Uri.parse(profile.website),
                  ),
                ),
            ],
          ),
          const SizedBox(height: CsSpace.md),
          Row(
            children: [
              _Stat(value: c.students, label: l10n.visitStudentsLabel),
              _Stat(value: profile.classGroups, label: l10n.visitClassGroups),
              _Stat(value: profile.busRoutes, label: l10n.visitBusRoutes),
              _Stat(value: c.posts7d, label: l10n.visitPostsLabel),
            ],
          ),
          const SizedBox(height: CsSpace.sm),
          if (!profile.mine)
            Container(
              padding: const EdgeInsets.all(CsSpace.sm + 4),
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(CsRadius.md),
              ),
              child: Row(
                children: [
                  Icon(CsIcons.visitCampus, size: 18, color: cs.primary),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.visitReadOnlyNote,
                      style: context.text.bodySmall,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          countText(context, value),
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: context.text.bodySmall?.copyWith(
            color: context.cs.textSecondary,
          ),
        ),
      ],
    ),
  );
}

/// A university's short name on a badge: its slug when short ("DU",
/// "BUET", "NSU"), else the first letters of its main words.
class CampusMark extends StatelessWidget {
  const CampusMark({super.key, required this.campus, this.size = 44});

  final CampusSummary campus;
  final double size;

  static const _skip = {'of', 'and', '&', 'the', 'for', 'in', 'at'};

  static String shortName(CampusSummary c) {
    final slug = c.slug.replaceAll('-', '');
    if (slug.isNotEmpty && slug.length <= 5) return slug.toUpperCase();
    final words = [
      for (final w in c.name.split(RegExp(r'[\s-]+')))
        if (w.isNotEmpty && !_skip.contains(w.toLowerCase())) w,
    ];
    return words.take(3).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: FittedBox(
        child: Text(
          shortName(campus),
          style: context.text.titleMedium?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
