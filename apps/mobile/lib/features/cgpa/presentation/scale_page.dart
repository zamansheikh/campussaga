import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cgpa_cubit.dart';
import 'cgpa_format.dart';

/// The grading scale (UGC or the university's own) and how retakes count.
class ScalePage extends StatefulWidget {
  const ScalePage({super.key});

  @override
  State<ScalePage> createState() => _ScalePageState();
}

class _ScaleRow {
  _ScaleRow(Grade g)
    : letter = TextEditingController(text: g.letter),
      points = TextEditingController(text: g.points.toStringAsFixed(2)),
      min = TextEditingController(text: g.minMarks.toStringAsFixed(0));

  final TextEditingController letter;
  final TextEditingController points;
  final TextEditingController min;

  Grade get grade => Grade(
    letter.text.trim(),
    parseNumber(points.text) ?? -1,
    parseNumber(min.text) ?? -1,
  );

  void dispose() {
    letter.dispose();
    points.dispose();
    min.dispose();
  }
}

class _ScalePageState extends State<ScalePage> {
  late final CgpaBook _book = context.read<CgpaCubit>().state.book;
  late bool _custom = _book.scale.custom;
  late final List<_ScaleRow> _rows = [
    for (final g in _book.scale.grades) _ScaleRow(g),
  ];

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  GradeScale get _draft =>
      GradeScale(custom: true, grades: [for (final r in _rows) r.grade]);

  String _problemText(AppLocalizations l10n, ScaleProblem p) => switch (p) {
    ScaleProblem.empty => l10n.cgpaProblemEmpty,
    ScaleProblem.letterMissing ||
    ScaleProblem.letterTwice => l10n.cgpaProblemLetter,
    ScaleProblem.pointsRange => l10n.cgpaProblemPoints,
    ScaleProblem.marksRange || ScaleProblem.marksTwice => l10n.cgpaProblemMarks,
    ScaleProblem.noZero => l10n.cgpaProblemZero,
    ScaleProblem.order => l10n.cgpaProblemOrder,
  };

  void _save() {
    final cubit = context.read<CgpaCubit>();
    cubit.setScale(_custom ? _draft.sorted() : GradeScale.ugc);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final cubit = context.read<CgpaCubit>();
    final retake = context.select((CgpaCubit c) => c.state.book.retake);
    final problems = _custom
        ? {for (final p in _draft.problems()) _problemText(l10n, p)}
        : const <String>{};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cgpaGradingScale)),
      body: CsPage(
        children: [
          CsSection(
            children: [
              RadioGroup<bool>(
                groupValue: _custom,
                onChanged: (v) => setState(() {
                  _custom = v ?? false;
                  // Start a custom scale from the UGC one.
                  if (_custom && _rows.isEmpty) {
                    _rows.addAll([
                      for (final g in GradeScale.ugc.grades) _ScaleRow(g),
                    ]);
                  }
                }),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      value: false,
                      title: Text(l10n.cgpaUseUgc),
                      subtitle: Text(l10n.cgpaUseUgcHint),
                    ),
                    RadioListTile<bool>(
                      value: true,
                      title: Text(l10n.cgpaUseCustom),
                      subtitle: Text(l10n.cgpaUseCustomHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.lg),
          if (!_custom)
            CsSection(
              title: l10n.cgpaScaleUgc,
              children: [
                for (final g in GradeScale.ugc.grades)
                  CsRow(
                    icon: CsIcons.academic,
                    title: g.letter,
                    subtitle: g.minMarks == 0
                        ? '< ${creditsText(context, GradeScale.ugc.grades[GradeScale.ugc.grades.length - 2].minMarks)}'
                        : '≥ ${creditsText(context, g.minMarks)}',
                    showChevron: false,
                    trailing: Text(
                      gpaText(context, g.points),
                      style: context.text.titleMedium,
                    ),
                  ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.cgpaGradeShort,
                    style: context.text.labelMedium,
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  flex: 3,
                  child: Text(l10n.cgpaPoints, style: context.text.labelMedium),
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.cgpaMinMarks,
                    style: context.text.labelMedium,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: CsSpace.xs),
            for (final (i, r) in _rows.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: CsSpace.sm),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _cell(r.letter, text: true)),
                    const SizedBox(width: CsSpace.sm),
                    Expanded(flex: 3, child: _cell(r.points)),
                    const SizedBox(width: CsSpace.sm),
                    Expanded(flex: 3, child: _cell(r.min)),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        tooltip: l10n.deleteAction,
                        icon: const Icon(CsIcons.close),
                        onPressed: () =>
                            setState(() => _rows.removeAt(i).dispose()),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _rows.add(_ScaleRow(const Grade('', 0, 0)))),
                icon: const Icon(CsIcons.add),
                label: Text(l10n.cgpaAddGrade),
              ),
            ),
            for (final p in problems)
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xs),
                child: Text(
                  p,
                  style: context.text.bodySmall?.copyWith(color: cs.error),
                ),
              ),
          ],
          const SizedBox(height: CsSpace.lg),
          CsSection(
            title: l10n.cgpaRetakeRule,
            children: [
              RadioGroup<RetakeRule>(
                groupValue: retake,
                onChanged: (v) {
                  if (v != null) cubit.setRetake(v);
                },
                child: Column(
                  children: [
                    RadioListTile<RetakeRule>(
                      value: RetakeRule.best,
                      title: Text(l10n.cgpaRetakeBest),
                      subtitle: Text(l10n.cgpaRetakeBestHint),
                    ),
                    RadioListTile<RetakeRule>(
                      value: RetakeRule.latest,
                      title: Text(l10n.cgpaRetakeLatest),
                    ),
                    RadioListTile<RetakeRule>(
                      value: RetakeRule.all,
                      title: Text(l10n.cgpaRetakeAll),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.xs,
              CsSpace.sm,
              CsSpace.xs,
              0,
            ),
            child: Text(l10n.cgpaRetakeHint, style: context.text.bodySmall),
          ),
          const SizedBox(height: CsSpace.lg),
          FilledButton(
            onPressed: problems.isEmpty ? _save : null,
            child: Text(l10n.cgpaSave),
          ),
        ],
      ),
    );
  }

  Widget _cell(TextEditingController c, {bool text = false}) => TextField(
    controller: c,
    textAlign: TextAlign.center,
    maxLength: text ? 4 : 6,
    keyboardType: text
        ? TextInputType.text
        : const TextInputType.numberWithOptions(decimal: true),
    textCapitalization: TextCapitalization.characters,
    decoration: const InputDecoration(counterText: '', isDense: true),
    onChanged: (_) => setState(() {}),
  );
}
