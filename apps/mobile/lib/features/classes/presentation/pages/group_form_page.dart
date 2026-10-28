import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// Create a group (the student becomes its CR), or edit its details.
class GroupFormPage extends StatefulWidget {
  const GroupFormPage({super.key, this.groupId});

  /// null = create a new group.
  final String? groupId;

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  late final ClassGroup? _group = widget.groupId == null
      ? null
      : context.read<MyClassesCubit>().state.group(widget.groupId!);
  late final UserProfile? _user = context.read<AuthBloc>().state.user;

  late final _department = TextEditingController(
    text: _group?.department ?? _user?.department ?? '',
  );
  late final _batch = TextEditingController(
    text: _group?.batch ?? _user?.batch ?? '',
  );
  late final _section = TextEditingController(text: _group?.section ?? '');
  late final _semester = TextEditingController(
    text: _group?.semester ?? _semesters().first,
  );

  final _missing = <String>{};
  Failure? _failure;
  bool _busy = false;

  /// Findable by search at the university (edit only; new groups are).
  late bool _discoverable = _group?.discoverable ?? true;

  /// Groups of the same department and batch, so a CR joins instead of
  /// making a second routine for the same class (create only).
  List<FoundGroup> _similar = const [];
  Timer? _similarTimer;
  String _similarFor = '';

  bool get _editing => _group != null;

  @override
  void initState() {
    super.initState();
    if (!_editing) {
      for (final c in [_department, _batch, _section]) {
        c.addListener(_scheduleSimilar);
      }
      _findSimilar();
    }
  }

  void _scheduleSimilar() {
    _similarTimer?.cancel();
    _similarTimer = Timer(const Duration(milliseconds: 500), _findSimilar);
  }

  Future<void> _findSimilar() async {
    final department = _department.text.trim();
    final batch = _batch.text.trim();
    final section = _section.text.trim();
    final key = '$department|$batch|$section'.toLowerCase();
    if (key == _similarFor) return;
    _similarFor = key;
    if (department.isEmpty || batch.isEmpty) {
      if (_similar.isNotEmpty) setState(() => _similar = const []);
      return;
    }
    try {
      final found = await context.read<MyClassesCubit>().similarGroups(
        department: department,
        batch: batch,
        section: section,
      );
      if (mounted && key == _similarFor) setState(() => _similar = found);
    } on Failure {
      // Only a hint: offline or failing, the form still works.
    }
  }

  /// This term and the next ("Fall 2026", "Spring 2027"): Spring is
  /// January to April, Summer May to August, Fall September to December.
  static List<String> _semesters() {
    final now = appNow();
    const terms = ['Spring', 'Summer', 'Fall'];
    final i = (now.month - 1) ~/ 4;
    final next = i == 2 ? 0 : i + 1;
    return [
      '${terms[i]} ${now.year}',
      '${terms[next]} ${i == 2 ? now.year + 1 : now.year}',
    ];
  }

  @override
  void dispose() {
    _similarTimer?.cancel();
    _department.dispose();
    _batch.dispose();
    _section.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final draft = GroupDraft(
      department: _department.text.trim(),
      batch: _batch.text.trim(),
      section: _section.text.trim(),
      semester: _semester.text.trim(),
      discoverable: _editing && _discoverable != _group!.discoverable
          ? _discoverable
          : null,
    );
    setState(() {
      _failure = null;
      _missing
        ..clear()
        ..addAll([
          if (draft.department.isEmpty) 'department',
          if (draft.batch.isEmpty) 'batch',
          if (draft.semester.isEmpty) 'semester',
        ]);
    });
    if (_missing.isNotEmpty) return;
    setState(() => _busy = true);
    final cubit = context.read<MyClassesCubit>();
    try {
      if (_editing) {
        await cubit.updateGroup(_group!.id, draft);
        if (mounted) context.pop();
      } else {
        final g = await cubit.create(draft);
        if (mounted) context.pushReplacement(Routes.group(g.id));
      }
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? err(String field) =>
        _missing.contains(field) ? l10n.errorFieldRequired : null;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? l10n.editGroup : l10n.createGroup)),
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            CsSpace.sm,
            CsSpace.lg,
            CsSpace.lg,
          ),
          children: [
            if (!_editing) ...[
              Text(
                l10n.createSubtitle,
                style: context.text.bodyLarge?.copyWith(
                  color: context.cs.textSecondary,
                ),
              ),
              const SizedBox(height: CsSpace.lg),
            ],
            TextField(
              controller: _department,
              enabled: !_busy,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.departmentLabel,
                hintText: l10n.departmentHint,
                prefixIcon: const Icon(CsIcons.department),
                errorText: err('department'),
              ),
            ),
            const SizedBox(height: CsSpace.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batch,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.batchLabel,
                      prefixIcon: const Icon(CsIcons.groups),
                      errorText: err('batch'),
                    ),
                  ),
                ),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: TextField(
                    controller: _section,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.sectionLabel,
                      hintText: l10n.sectionHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _semester,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.semesterLabel,
                hintText: l10n.semesterHint,
                prefixIcon: const Icon(CsIcons.date),
                errorText: err('semester'),
              ),
            ),
            const SizedBox(height: CsSpace.sm),
            Wrap(
              spacing: CsSpace.sm,
              children: [
                for (final s in _semesters())
                  ActionChip(
                    label: Text(s),
                    onPressed: _busy
                        ? null
                        : () => setState(() => _semester.text = s),
                  ),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: CsSpace.lg),
              CsSection(
                children: [
                  SwitchListTile(
                    secondary: const Icon(CsIcons.search),
                    title: Text(
                      l10n.findableTitle(
                        _user?.university?.shortName ?? l10n.universityLabel,
                      ),
                    ),
                    subtitle: Text(l10n.findableBody),
                    value: _discoverable,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _discoverable = v),
                  ),
                ],
              ),
            ],
            if (!_editing && _similar.isNotEmpty) ...[
              const SizedBox(height: CsSpace.lg),
              SimilarGroupsCard(groups: _similar),
            ],
            if (_failure != null) ...[
              const SizedBox(height: CsSpace.md),
              NoticeBanner(text: classErrorText(l10n, _failure!)),
            ],
            const SizedBox(height: CsSpace.lg),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_editing ? l10n.saveProfile : l10n.createAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// "This class may already exist": groups like the one being created, each
/// with "Join instead".
class SimilarGroupsCard extends StatelessWidget {
  const SimilarGroupsCard({super.key, required this.groups});

  final List<FoundGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(CsSpace.md),
        decoration: BoxDecoration(
          color: cs.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(CsRadius.md + 2),
          border: Border.all(color: cs.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CsIcons.info, color: cs.accent),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: Text(
                    l10n.similarGroupsTitle,
                    style: context.text.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.xs),
            Text(
              l10n.similarGroupsBody,
              style: context.text.bodySmall?.copyWith(color: cs.textSecondary),
            ),
            for (final g in groups) ...[
              const SizedBox(height: CsSpace.sm),
              Material(
                color: cs.surface,
                borderRadius: BorderRadius.circular(CsRadius.md),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CsSpace.md,
                    CsSpace.sm,
                    CsSpace.xs,
                    CsSpace.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.title, style: context.text.titleSmall),
                            Text(
                              [
                                if (g.semester.isNotEmpty) g.semester,
                                l10n.membersCount(g.memberCount),
                                if (g.crName != null && g.crName!.isNotEmpty)
                                  l10n.findClassCr(g.crName!),
                              ].join(' · '),
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.push(Routes.classPreview(g.id)),
                        child: Text(l10n.joinInstead),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
