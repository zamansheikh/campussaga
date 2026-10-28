import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// Find your class: search the class groups of the student's university by
/// department, batch, course code or teacher, then open one's routine.
class FindClassPage extends StatefulWidget {
  const FindClassPage({super.key});

  /// How long typing must pause before a search goes out.
  static const debounce = Duration(milliseconds: 350);

  @override
  State<FindClassPage> createState() => _FindClassPageState();
}

class _FindClassPageState extends State<FindClassPage> {
  final _query = TextEditingController();
  Timer? _debounce;

  /// Bumped by every new search, so a slow older answer is dropped.
  int _seq = 0;
  String _searched = '';
  List<FoundGroup> _items = const [];
  int _page = 1;
  bool _more = false;
  bool _loading = true;
  bool _loadingMore = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {}); // the clear button
    _debounce?.cancel();
    _debounce = Timer(FindClassPage.debounce, _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final q = _query.text.trim();
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final r = await context.read<MyClassesCubit>().searchGroups(q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _searched = q;
        _items = r.items;
        _more = r.more;
        _page = 1;
      });
    } on Failure catch (f) {
      if (mounted && seq == _seq) setState(() => _failure = f);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final seq = _seq;
    setState(() => _loadingMore = true);
    try {
      final r = await context.read<MyClassesCubit>().searchGroups(
        _searched,
        page: _page + 1,
      );
      if (!mounted || seq != _seq) return;
      final seen = {for (final g in _items) g.id};
      setState(() {
        _items = [..._items, ...r.items.where((g) => !seen.contains(g.id))];
        _more = r.more;
        _page++;
      });
    } on Failure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(classErrorText(AppLocalizations.of(context), f)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _clear() {
    _query.clear();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findClass)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.screen,
                CsSpace.sm,
                CsSpace.screen,
                CsSpace.sm,
              ),
              child: TextField(
                controller: _query,
                onChanged: _onChanged,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: l10n.findClassHint,
                  prefixIcon: const Icon(CsIcons.search),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.cancel,
                          icon: const Icon(CsIcons.clear),
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _body(context, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    final f = _failure;
    if (f != null) {
      final offline = f is NetworkFailure;
      return CsPage(
        children: [
          const SizedBox(height: CsSpace.xl),
          CsEmptyState(
            icon: offline ? CsIcons.offline : CsIcons.error,
            title: offline ? l10n.findClassOffline : classErrorText(l10n, f),
            actionLabel: l10n.tryAgain,
            onAction: _search,
          ),
        ],
      );
    }
    if (_loading && _items.isEmpty) return const SizedBox.shrink();
    return CsPage(
      children: [
        if (_searched.isEmpty) ...[
          Text(
            l10n.findClassIntro,
            style: context.text.bodyMedium?.copyWith(
              color: context.cs.textSecondary,
            ),
          ),
          const SizedBox(height: CsSpace.md),
        ],
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.lg),
            child: CsEmptyState(
              icon: CsIcons.searchEmpty,
              title: l10n.findClassEmptyTitle,
              message: l10n.findClassEmptyBody,
              actionLabel: l10n.joinWithCode,
              onAction: () => context.push(Routes.joinGroup),
            ),
          )
        else ...[
          for (final g in _items) ...[
            FoundGroupCard(
              group: g,
              onTap: () => context.push(Routes.classPreview(g.id)),
            ),
            const SizedBox(height: CsSpace.sm),
          ],
          if (_more)
            Center(
              child: _loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(CsSpace.sm),
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: _loadMore,
                      child: Text(l10n.findClassMore),
                    ),
            ),
          const SizedBox(height: CsSpace.md),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push(Routes.joinGroup),
              icon: const Icon(CsIcons.key, size: 18),
              label: Text(l10n.findClassHaveCode),
            ),
          ),
        ],
      ],
    );
  }
}

/// A search result: the section, its semester, size and CR, and its courses.
class FoundGroupCard extends StatelessWidget {
  const FoundGroupCard({super.key, required this.group, required this.onTap});

  final FoundGroup group;
  final VoidCallback onTap;

  /// Course chips shown before "+N".
  static const _maxChips = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final g = group;
    final shown = g.courses.take(_maxChips).toList();
    final extra = g.courses.length - shown.length;
    final meta = [
      if (g.semester.isNotEmpty) g.semester,
      l10n.membersCount(g.memberCount),
      if (g.crName != null && g.crName!.isNotEmpty) l10n.findClassCr(g.crName!),
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(CsRadius.md),
                    ),
                    child: Icon(
                      CsIcons.groups,
                      size: 22,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: CsSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.title, style: context.text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: context.text.bodySmall?.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (g.isMember)
                    CsBadge(
                      icon: CsIcons.checkCircle,
                      label: l10n.findClassJoined,
                      tone: CsBadgeTone.success,
                    )
                  else
                    Icon(CsIcons.chevronRight, color: cs.textSecondary),
                ],
              ),
              if (shown.isNotEmpty) ...[
                const SizedBox(height: CsSpace.md),
                Wrap(
                  spacing: CsSpace.xs,
                  runSpacing: CsSpace.xs,
                  children: [
                    for (final c in shown)
                      CsBadge(label: c.code, tone: CsBadgeTone.neutral),
                    if (extra > 0)
                      CsBadge(
                        label: '+${numberText(context, extra)}',
                        tone: CsBadgeTone.neutral,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
