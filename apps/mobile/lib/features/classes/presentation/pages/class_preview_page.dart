import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// A group's weekly routine before joining: tick the courses you take, then
/// join the whole section or add only those courses.
class ClassPreviewPage extends StatefulWidget {
  const ClassPreviewPage({super.key, required this.groupId, this.code});

  final String groupId;

  /// The join code, for a group that isn't findable.
  final String? code;

  @override
  State<ClassPreviewPage> createState() => _ClassPreviewPageState();
}

class _ClassPreviewPageState extends State<ClassPreviewPage> {
  RoutinePreview? _preview;
  List<FoundCourse> _courses = const [];
  Set<String> _picked = {};
  Failure? _loadFailure;
  Failure? _joinFailure;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailure = null);
    try {
      final p = await context.read<MyClassesCubit>().routinePreview(
        widget.groupId,
        code: widget.code,
      );
      if (!mounted) return;
      final courses = _coursesOf(p);
      setState(() {
        _preview = p;
        _courses = courses;
        _picked = {
          for (final c in courses)
            if (!p.hiddenCourses.contains(c.key)) c.key,
        };
      });
    } on Failure catch (f) {
      if (mounted) setState(() => _loadFailure = f);
    }
  }

  /// The group's courses, from the search data or else from its slots.
  static List<FoundCourse> _coursesOf(RoutinePreview p) {
    if (p.group.courses.isNotEmpty) return p.group.courses;
    final byKey = <String, FoundCourse>{};
    for (final s in p.slots) {
      byKey.putIfAbsent(
        courseKey(s.courseCode),
        () => FoundCourse(
          key: courseKey(s.courseCode),
          code: s.courseCode,
          title: s.courseTitle,
          teacher: s.teacher,
        ),
      );
    }
    return byKey.values.toList()..sort((a, b) => a.code.compareTo(b.code));
  }

  void _toggle(String key) => setState(() {
    _picked.contains(key) ? _picked.remove(key) : _picked.add(key);
    _joinFailure = null;
  });

  Future<void> _join(Set<String> courses) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _joinFailure = null;
    });
    try {
      final g = await context.read<MyClassesCubit>().joinCourses(
        widget.groupId,
        courses,
        code: widget.code,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.addedToRoutine)));
      context.pushReplacement(Routes.group(g.id));
    } on Failure catch (f) {
      if (mounted) setState(() => _joinFailure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _preview;
    final f = _loadFailure;
    return Scaffold(
      appBar: AppBar(title: Text(p?.group.title ?? l10n.findClass)),
      bottomNavigationBar: p == null ? null : _actions(context, l10n, p),
      body: SafeArea(
        child: f != null
            ? CsPage(
                children: [
                  const SizedBox(height: CsSpace.xl),
                  CsEmptyState(
                    icon: f is NetworkFailure ? CsIcons.offline : CsIcons.error,
                    title: f is NetworkFailure
                        ? l10n.findClassOffline
                        : classErrorText(l10n, f),
                    actionLabel: l10n.tryAgain,
                    onAction: _load,
                  ),
                ],
              )
            : p == null
            ? const Center(child: CircularProgressIndicator())
            : _content(context, l10n, p),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    RoutinePreview p,
  ) {
    final cs = context.cs;
    final g = p.group;
    final byDay = <int, List<ClassSlot>>{};
    for (final s in p.slots) {
      byDay.putIfAbsent(s.weekday, () => []).add(s);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.startMin.compareTo(b.startMin));
    }
    return CsPage(
      children: [
        Text(g.title, style: context.text.headlineSmall),
        const SizedBox(height: CsSpace.xs),
        Text(
          [
            if (g.semester.isNotEmpty) g.semester,
            l10n.membersCount(g.memberCount),
            if (g.crName != null && g.crName!.isNotEmpty)
              l10n.findClassCr(g.crName!),
          ].join(' · '),
          style: context.text.bodyMedium?.copyWith(color: cs.textSecondary),
        ),
        if (g.isMember) ...[
          const SizedBox(height: CsSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsBadge(
              icon: CsIcons.checkCircle,
              label: l10n.alreadyMember,
              tone: CsBadgeTone.success,
            ),
          ),
        ],
        const SizedBox(height: CsSpace.lg),
        if (_courses.isEmpty)
          Text(l10n.previewNoClasses, style: context.text.bodyMedium)
        else ...[
          Text(
            l10n.previewPickHint,
            style: context.text.bodyMedium?.copyWith(color: cs.textSecondary),
          ),
          const SizedBox(height: CsSpace.sm),
          CsSection(
            title: l10n.courses,
            children: [
              for (final c in _courses)
                CsRow(
                  icon: CsIcons.course,
                  title: c.code,
                  subtitle: c.title.isEmpty && c.teacher.isEmpty
                      ? null
                      : [
                          c.title,
                          c.teacher,
                        ].where((x) => x.isNotEmpty).join(' · '),
                  showChevron: false,
                  trailing: Checkbox(
                    value: _picked.contains(c.key),
                    onChanged: _busy ? null : (_) => _toggle(c.key),
                  ),
                  onTap: _busy ? null : () => _toggle(c.key),
                ),
            ],
          ),
          for (final day in weekOrder)
            if (byDay[day] case final slots?) ...[
              const SizedBox(height: CsSpace.lg),
              CsSection(
                title: weekdayName(context, day),
                children: [
                  for (final s in slots)
                    Opacity(
                      opacity: _picked.contains(courseKey(s.courseCode))
                          ? 1
                          : 0.45,
                      child: CsRow(
                        icon: CsIcons.time,
                        title: [
                          s.courseCode,
                          if (s.courseTitle.isNotEmpty) s.courseTitle,
                        ].join(' · '),
                        subtitle: [
                          rangeText(context, s),
                          if (s.room.isNotEmpty) s.room,
                        ].join(' · '),
                        showChevron: false,
                      ),
                    ),
                ],
              ),
            ],
        ],
      ],
    );
  }

  Widget _actions(
    BuildContext context,
    AppLocalizations l10n,
    RoutinePreview p,
  ) {
    final all = {for (final c in _courses) c.key};
    final everything = _picked.length == all.length;
    final member = p.group.isMember;
    Widget label(String text) => _busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text);
    final List<Widget> buttons;
    if (member) {
      buttons = [
        FilledButton(
          onPressed: _busy || (_picked.isEmpty && all.isNotEmpty)
              ? null
              : () => _join({..._picked}),
          child: label(l10n.saveMyCourses),
        ),
        const SizedBox(height: CsSpace.xs),
        TextButton(
          onPressed: _busy
              ? null
              : () => context.pushReplacement(Routes.group(p.group.id)),
          child: Text(l10n.openGroup),
        ),
      ];
    } else if (everything) {
      buttons = [
        FilledButton(
          onPressed: _busy ? null : () => _join(all),
          child: label(l10n.joinWholeSection),
        ),
      ];
    } else {
      buttons = [
        FilledButton(
          onPressed: _busy || _picked.isEmpty
              ? null
              : () => _join({..._picked}),
          child: label(l10n.addSelectedCourses(_picked.length)),
        ),
        const SizedBox(height: CsSpace.xs),
        OutlinedButton(
          onPressed: _busy ? null : () => _join(all),
          child: Text(l10n.joinWholeSection),
        ),
      ];
    }
    return Material(
      color: context.cs.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.screen,
            CsSpace.sm,
            CsSpace.screen,
            CsSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_joinFailure != null) ...[
                NoticeBanner(text: classErrorText(l10n, _joinFailure!)),
                const SizedBox(height: CsSpace.sm),
              ],
              ...buttons,
            ],
          ),
        ),
      ),
    );
  }
}
