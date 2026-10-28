import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../voice_format.dart';

/// Why is this reported: a reason and optional details. Null = cancelled.
Future<(ReportReason, String)?> showReportSheet(BuildContext context) =>
    showModalBottomSheet<(ReportReason, String)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ReportSheet(),
    );

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
            Text(l10n.voiceReportTitle, style: context.text.titleLarge),
            const SizedBox(height: CsSpace.xs),
            Row(
              children: [
                Icon(
                  Icons.masks_outlined,
                  size: 16,
                  color: context.cs.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(l10n.voiceReportAnon, style: context.text.bodySmall),
              ],
            ),
            const SizedBox(height: CsSpace.sm),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (r) => setState(() => _reason = r),
              child: Column(
                children: [
                  for (final r in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: r,
                      contentPadding: EdgeInsets.zero,
                      title: Text(reportReasonLabel(l10n, r)),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.voiceReportDetails),
            ),
            const SizedBox(height: CsSpace.sm),
            FilledButton(
              onPressed: _reason == null
                  ? null
                  : () => Navigator.of(context).pop((_reason!, _details.text)),
              child: Text(l10n.voiceReport),
            ),
          ],
        ),
      ),
    );
  }
}

/// Officials: the next status and a note (required to reject).
Future<(IssueStatus, String)?> showStatusSheet(
  BuildContext context,
  IssueStatus from,
) => showModalBottomSheet<(IssueStatus, String)>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _StatusSheet(from: from),
);

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.from});

  final IssueStatus from;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  IssueStatus? _to;
  final _note = TextEditingController();
  bool _missingNote = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
            Text(l10n.voiceChangeStatus, style: context.text.titleLarge),
            const SizedBox(height: CsSpace.md),
            Wrap(
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                for (final s in widget.from.next)
                  ChoiceChip(
                    avatar: Icon(statusTone(s).icon, size: 18),
                    label: Text(statusLabel(l10n, s)),
                    selected: _to == s,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _to = s;
                      _missingNote = false;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.voiceStatusNote,
                hintText: l10n.voiceStatusNoteHint,
                errorText: _missingNote ? l10n.voiceNoteRequired : null,
              ),
            ),
            const SizedBox(height: CsSpace.sm),
            FilledButton(
              onPressed: _to == null
                  ? null
                  : () {
                      if (_to == IssueStatus.rejected &&
                          _note.text.trim().isEmpty) {
                        setState(() => _missingNote = true);
                        return;
                      }
                      Navigator.of(context).pop((_to!, _note.text.trim()));
                    },
              child: Text(l10n.voiceChangeStatus),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short text (official reply, reopen note). Null = cancelled.
Future<String?> showTextSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  int maxLength = 500,
  String? subtitle,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _TextSheet(
    title: title,
    hint: hint,
    action: action,
    maxLength: maxLength,
    subtitle: subtitle,
  ),
);

class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.title,
    required this.hint,
    required this.action,
    required this.maxLength,
    this.subtitle,
  });

  final String title;
  final String hint;
  final String action;
  final int maxLength;
  final String? subtitle;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(CsSpace.lg, 0, CsSpace.lg, CsSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: context.text.titleLarge),
          if (widget.subtitle != null) ...[
            const SizedBox(height: CsSpace.xs),
            Text(widget.subtitle!, style: context.text.bodySmall),
          ],
          const SizedBox(height: CsSpace.md),
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: widget.maxLength,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: widget.hint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: CsSpace.sm),
          FilledButton(
            onPressed: _text.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_text.text.trim()),
            child: Text(widget.action),
          ),
        ],
      ),
    ),
  );
}

/// Yes/no for a destructive action.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  String? body,
  required String action,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: dialog.cs.error),
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
