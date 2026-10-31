import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../verification/presentation/verification_text.dart';

/// Asks for a short text (a reason, a note). Null when cancelled; an
/// empty text is refused unless [required] is false.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String? body,
  required String label,
  required String action,
  bool required = true,
  bool destructive = false,
  int maxLength = 300,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextDialog(
    title: title,
    body: body,
    label: label,
    action: action,
    required: required,
    destructive: destructive,
    maxLength: maxLength,
  ),
);

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.body,
    required this.label,
    required this.action,
    required this.required,
    required this.destructive,
    required this.maxLength,
  });

  final String title;
  final String? body;
  final String label;
  final String action;
  final bool required;
  final bool destructive;
  final int maxLength;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.required && _controller.text.trim().isEmpty) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.body != null) ...[
            Text(widget.body!),
            const SizedBox(height: CsSpace.md),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: widget.maxLength,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _tried && widget.required
                  ? l10n.caReasonRequired
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: widget.destructive
              ? TextButton.styleFrom(foregroundColor: context.cs.error)
              : null,
          onPressed: _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// "Ask the VarsityKotha team": a note to the central inbox.
Future<void> askTeam(
  BuildContext context,
  EscalationKind kind, {
  String? targetId,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final note = await askText(
    context,
    title: l10n.caAskTeam,
    label: l10n.caAskTeamNote,
    action: l10n.caAskTeamSend,
    maxLength: 500,
  );
  if (note == null) return;
  try {
    await getIt<CampusAdminRepository>().escalate(
      kind,
      note,
      targetId: targetId,
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.caAskTeamSent)));
  } on Failure catch (f) {
    messenger.showSnackBar(
      SnackBar(content: Text(verificationErrorText(l10n, f))),
    );
  }
}

/// The "Ask the VarsityKotha team" row at the end of a detail screen.
class AskTeamRow extends StatelessWidget {
  const AskTeamRow({super.key, required this.kind, this.targetId});

  final EscalationKind kind;
  final String? targetId;

  @override
  Widget build(BuildContext context) => CsSection(
    children: [
      CsRow(
        icon: CsIcons.comment,
        title: AppLocalizations.of(context).caAskTeam,
        onTap: () => askTeam(context, kind, targetId: targetId),
      ),
    ],
  );
}

/// A student in a list: avatar, name, class and a verified/waiting pill.
class StudentTile extends StatelessWidget {
  const StudentTile({
    super.key,
    required this.student,
    this.onTap,
    this.trailing,
    this.isCr = false,
  });

  final CampusStudent student;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Shows a CR badge by the name.
  final bool isCr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = student.card;
    final name = card.name.isEmpty ? l10n.unnamedStudent : card.name;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            UserAvatar(
              userId: card.id,
              name: name,
              photoVersion: card.photoVersion,
              googlePhotoUrl: card.googlePhotoUrl,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(name, style: context.text.bodyLarge),
                      if (isCr)
                        CsBadge(label: l10n.roleCr, tone: CsBadgeTone.success),
                    ],
                  ),
                  if (card.classLine.isNotEmpty)
                    Text(
                      card.classLine,
                      style: context.text.bodySmall?.copyWith(
                        color: context.cs.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: CsSpace.sm),
              trailing!,
            ] else
              CsPill(
                label: student.verified
                    ? l10n.verifiedStudent
                    : l10n.notVerified,
                icon: student.verified ? CsIcons.verified : CsIcons.help,
                highlight: !student.verified,
              ),
          ],
        ),
      ),
    );
  }
}

/// Picks a verified student of the university by searching.
Future<CampusStudent?> pickStudent(BuildContext context) =>
    showModalBottomSheet<CampusStudent>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _StudentPicker(),
    );

class _StudentPicker extends StatefulWidget {
  const _StudentPicker();

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  final _query = TextEditingController();
  List<CampusStudent> _found = const [];
  bool _loading = true;
  Failure? _failure;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final round = ++_round;
    setState(() => _loading = true);
    try {
      final page = await getIt<CampusAdminRepository>().students(
        status: StudentStatus.verified,
        query: _query.text,
      );
      if (mounted && round == _round) {
        setState(() {
          _found = page.items;
          _failure = null;
          _loading = false;
        });
      }
    } on Failure catch (f) {
      if (mounted && round == _round) {
        setState(() {
          _failure = f;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(CsSpace.md),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => _search(),
                decoration: InputDecoration(
                  hintText: l10n.caSearchStudents,
                  prefixIcon: const Icon(CsIcons.search),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _failure != null
                  ? CsEmptyState(
                      icon: CsIcons.offline,
                      title: verificationErrorText(l10n, _failure!),
                    )
                  : _found.isEmpty
                  ? CsEmptyState(
                      icon: CsIcons.searchEmpty,
                      title: l10n.caNoStudents,
                    )
                  : ListView(
                      children: [
                        for (final s in _found)
                          StudentTile(
                            student: s,
                            trailing: const SizedBox.shrink(),
                            onTap: () => Navigator.of(context).pop(s),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
