import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import 'cgpa_format.dart';

/// "What GPA do I need in my remaining credits to reach my target CGPA?"
Future<void> showTargetSheet(BuildContext context, CgpaBook book) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _TargetSheet(book: book),
    );

class _TargetSheet extends StatefulWidget {
  const _TargetSheet({required this.book});

  final CgpaBook book;

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  final _target = TextEditingController();
  final _credits = TextEditingController();

  @override
  void dispose() {
    _target.dispose();
    _credits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final target = parseNumber(_target.text);
    final credits = parseNumber(_credits.text);
    final max = widget.book.scale.maxPoints;
    final plan =
        target == null || credits == null || target <= 0 || target > max
        ? null
        : planTarget(
            current: widget.book.cgpa,
            target: target,
            nextCredits: credits,
            maxPoints: max,
          );
    final (text, color) = switch (plan) {
      null => (l10n.cgpaTargetInvalid, cs.textSecondary),
      TargetNeeds(:final gpa) => (
        l10n.cgpaTargetNeeds(gpaText(context, gpa)),
        cs.textPrimary,
      ),
      TargetReached() => (l10n.cgpaTargetReached, cs.statusSolved.fg),
      TargetOutOfReach(:final gpa) => (
        l10n.cgpaTargetOut(gpa.isFinite ? gpaText(context, gpa) : '–'),
        cs.error,
      ),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            0,
            CsSpace.lg,
            CsSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.cgpaTarget, style: context.text.titleLarge),
              const SizedBox(height: CsSpace.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _target,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.cgpaTargetCgpa,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: TextField(
                      controller: _credits,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.cgpaNextCredits,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.md),
              Container(
                padding: const EdgeInsets.all(CsSpace.md),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(CsRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(CsIcons.target, color: color),
                    const SizedBox(width: CsSpace.sm),
                    Expanded(
                      child: Text(
                        text,
                        style: context.text.bodyLarge?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
