import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import 'cgpa_cubit.dart';
import 'cgpa_format.dart';
import 'target_sheet.dart';

enum _SemesterAction { rename, up, down, delete }

/// The CGPA calculator: overall result, then the semesters (oldest first).
class CgpaPage extends StatelessWidget {
  const CgpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CgpaCubit>();
    final state = context.watch<CgpaCubit>().state;
    final book = state.book;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cgpaTitle),
        actions: [
          IconButton(
            tooltip: l10n.cgpaGradingScale,
            icon: const Icon(CsIcons.scale),
            onPressed: () => context.push(Routes.cgpaScale),
          ),
          if (!book.isEmpty)
            PopupMenuButton<String>(
              icon: const Icon(CsIcons.more),
              onSelected: (_) => _confirmClear(context, cubit),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Text(
                    l10n.cgpaClearAll,
                    style: TextStyle(color: context.cs.error),
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: state.loaded && !book.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addSemester(context, cubit),
              icon: const Icon(CsIcons.add),
              label: Text(l10n.cgpaAddSemester),
            )
          : null,
      body: !state.loaded
          ? const Center(child: CircularProgressIndicator())
          : book.isEmpty
          ? CsEmptyState(
              icon: CsIcons.cgpa,
              title: l10n.cgpaEmptyTitle,
              message: l10n.cgpaEmptyBody,
              actionLabel: l10n.cgpaAddSemester,
              onAction: () => _addSemester(context, cubit),
            )
          : CsPage(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.screen,
                CsSpace.sm,
                CsSpace.screen,
                96,
              ),
              children: [
                _Summary(book: book),
                const SizedBox(height: CsSpace.lg),
                CsSection(
                  title: l10n.cgpaSemesters,
                  children: [
                    for (final (i, s) in book.semesters.indexed)
                      _SemesterRow(
                        semester: s,
                        result: book.semesterGpa(s),
                        first: i == 0,
                        last: i == book.semesters.length - 1,
                        onAction: (a) => _act(context, cubit, s, a),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  static Future<void> _addSemester(
    BuildContext context,
    CgpaCubit cubit,
  ) async {
    final name = await askSemesterName(context);
    if (name == null || !context.mounted) return;
    final id = cubit.addSemester(name);
    await context.push(Routes.cgpaSemester(id));
  }

  static Future<void> _act(
    BuildContext context,
    CgpaCubit cubit,
    Semester s,
    _SemesterAction a,
  ) async {
    final l10n = AppLocalizations.of(context);
    switch (a) {
      case _SemesterAction.rename:
        final name = await askSemesterName(context, current: s.name);
        if (name != null) cubit.renameSemester(s.id, name);
      case _SemesterAction.up:
        cubit.moveSemester(s.id, -1);
      case _SemesterAction.down:
        cubit.moveSemester(s.id, 1);
      case _SemesterAction.delete:
        final ok = await confirmDelete(context, l10n.cgpaDeleteSemesterTitle);
        if (ok) cubit.deleteSemester(s.id);
    }
  }

  static Future<void> _confirmClear(
    BuildContext context,
    CgpaCubit cubit,
  ) async {
    final ok = await confirmDelete(
      context,
      AppLocalizations.of(context).cgpaClearTitle,
    );
    if (ok) await cubit.clearAll();
  }
}

/// Asks for a semester name ("Spring 2026"); null when cancelled.
Future<String?> askSemesterName(BuildContext context, {String? current}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(current: current),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({this.current});

  final String? current;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done() {
    final v = _name.text.trim();
    if (v.isNotEmpty) Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.current == null ? l10n.cgpaAddSemester : l10n.cgpaRename,
      ),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.cgpaSemesterName,
          hintText: l10n.cgpaSemesterHint,
        ),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _done, child: Text(l10n.cgpaSave)),
      ],
    );
  }
}

/// A delete confirmation; true when confirmed.
Future<bool> confirmDelete(BuildContext context, String title) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
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
  return ok ?? false;
}

class _Summary extends StatelessWidget {
  const _Summary({required this.book});

  final CgpaBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = book.cgpa;
    final last = book.lastSemesterGpa;
    const white = Colors.white;
    final dim = white.withValues(alpha: 0.78);
    return Container(
      padding: const EdgeInsets.all(CsSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        // The brand teal in both themes (as on Today), so white text reads.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.cgpaLabel,
                style: context.text.labelLarge?.copyWith(color: dim),
              ),
              const Spacer(),
              Text(
                book.scale.custom ? l10n.cgpaScaleCustom : l10n.cgpaScaleUgc,
                style: context.text.labelMedium?.copyWith(color: dim),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.xs),
          Text(
            all.gpa == null ? '–' : gpaText(context, all.gpa!),
            style: context.text.displaySmall?.copyWith(
              color: white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (all.gpa == null)
            Text(
              l10n.cgpaNoGrades,
              style: context.text.bodyMedium?.copyWith(color: dim),
            ),
          const SizedBox(height: CsSpace.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.cgpaCreditsEarned,
                  value: creditsText(context, all.creditsEarned),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: l10n.cgpaLastSemester,
                  value: last.gpa == null ? '–' : gpaText(context, last.gpa!),
                ),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.md),
          OutlinedButton.icon(
            // On the brand card: see-through, white text and border (the
            // theme's outlined buttons have a solid surface).
            style: OutlinedButton.styleFrom(
              foregroundColor: white,
              backgroundColor: white.withValues(alpha: 0.12),
              side: BorderSide(color: white.withValues(alpha: 0.5)),
            ),
            onPressed: () => showTargetSheet(context, book),
            icon: const Icon(CsIcons.target),
            label: Text(l10n.cgpaTarget),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: context.text.titleLarge?.copyWith(color: Colors.white),
      ),
      Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
    ],
  );
}

class _SemesterRow extends StatelessWidget {
  const _SemesterRow({
    required this.semester,
    required this.result,
    required this.first,
    required this.last,
    required this.onAction,
  });

  final Semester semester;
  final GpaResult result;
  final bool first;
  final bool last;
  final void Function(_SemesterAction) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitle = result.gpa == null
        ? '${l10n.cgpaNoGrades} · ${l10n.cgpaCoursesCount(semester.courses.length)}'
        : '${l10n.cgpaGpa(gpaText(context, result.gpa!))} · '
              '${l10n.cgpaCredits(creditsText(context, result.creditsAttempted))}';
    return CsRow(
      icon: CsIcons.academic,
      title: semester.name,
      subtitle: subtitle,
      showChevron: false,
      onTap: () => context.push(Routes.cgpaSemester(semester.id)),
      trailing: PopupMenuButton<_SemesterAction>(
        icon: const Icon(CsIcons.more),
        onSelected: onAction,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _SemesterAction.rename,
            child: Text(l10n.cgpaRename),
          ),
          if (!first)
            PopupMenuItem(
              value: _SemesterAction.up,
              child: Text(l10n.cgpaMoveUp),
            ),
          if (!last)
            PopupMenuItem(
              value: _SemesterAction.down,
              child: Text(l10n.cgpaMoveDown),
            ),
          PopupMenuItem(
            value: _SemesterAction.delete,
            child: Text(
              l10n.deleteAction,
              style: TextStyle(color: context.cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
