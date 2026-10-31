import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The extras of a course in the class details, compact: one row of chips
/// (the chat group, the Classroom code, materials, the teacher's email)
/// and the notes under them. Only what the CR added shows; the CR also
/// gets a button to add or edit them ([onEdit]).
class CourseLinks extends StatelessWidget {
  const CourseLinks({super.key, required this.info, this.onEdit});

  final CourseInfo info;

  /// The CR: add or edit the links.
  final VoidCallback? onEdit;

  static final classroomUrl = Uri.parse('https://classroom.google.com/');

  void _open(BuildContext context, Uri uri) =>
      CsLinkText.onOpen?.call(context, uri);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final i = info;
    if (i.isEmpty) {
      return onEdit == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(CsIcons.addCircle, size: 20),
                label: Text(l10n.courseLinksAdd),
              ),
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CsSectionTitle(
          title: l10n.courseLinks,
          action: onEdit == null
              ? null
              : TextButton(onPressed: onEdit, child: Text(l10n.editAction)),
        ),
        Wrap(
          spacing: CsSpace.sm,
          runSpacing: CsSpace.sm,
          children: [
            if (i.chatLink.isNotEmpty)
              _LinkChip(
                icon: CsIcons.campus,
                label: chatAppName(i.chatLink),
                tooltip: l10n.courseChat,
                onTap: () => _open(context, Uri.parse(i.chatLink)),
              ),
            if (i.classroomCode.isNotEmpty)
              _ClassroomChip(
                code: i.classroomCode,
                onOpen: () => _open(context, classroomUrl),
              ),
            if (i.materialsLink.isNotEmpty)
              _LinkChip(
                icon: CsIcons.folder,
                label: l10n.courseMaterialsShort,
                tooltip: l10n.courseMaterials,
                onTap: () => _open(context, Uri.parse(i.materialsLink)),
              ),
            if (i.teacherEmail.isNotEmpty)
              _LinkChip(
                icon: CsIcons.email,
                label: i.teacherEmail,
                tooltip: l10n.courseTeacherEmail,
                onTap: () =>
                    _open(context, Uri(scheme: 'mailto', path: i.teacherEmail)),
              ),
          ],
        ),
        if (i.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.sm + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    CsIcons.note,
                    size: 18,
                    color: context.cs.textSecondary,
                  ),
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: CsLinkText(
                    i.notes,
                    style: context.text.bodyMedium,
                    selectable: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A small tappable pill: icon and a short label.
class _LinkChip extends StatelessWidget {
  const _LinkChip({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        shape: StadiumBorder(side: BorderSide(color: cs.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CsSpace.sm + 4,
              vertical: CsSpace.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailing, size: 14, color: cs.textSecondary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Classroom code: a tap copies it; for a few seconds the chip then
/// says "Copied · Open Classroom" and a tap opens Classroom to paste it.
class _ClassroomChip extends StatefulWidget {
  const _ClassroomChip({required this.code, required this.onOpen});

  final String code;
  final VoidCallback onOpen;

  @override
  State<_ClassroomChip> createState() => _ClassroomChipState();
}

class _ClassroomChipState extends State<_ClassroomChip> {
  Timer? _reset;
  bool _copied = false;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedSwitcher(
      duration: CsMotion.fast,
      child: _copied
          ? _LinkChip(
              key: const ValueKey('copied'),
              icon: CsIcons.checkCircle,
              label: '${l10n.courseCopied} · ${l10n.courseOpenClassroom}',
              tooltip: l10n.courseOpenClassroom,
              trailing: CsIcons.openExternal,
              onTap: widget.onOpen,
            )
          : _LinkChip(
              key: const ValueKey('code'),
              icon: CsIcons.academic,
              label: l10n.courseClassroomChip(widget.code),
              tooltip: l10n.courseClassroom,
              trailing: CsIcons.copy,
              onTap: _copy,
            ),
    );
  }
}

/// "WhatsApp", "Messenger", "Telegram", "Discord", or the site's name.
String chatAppName(String link) {
  final host = linkHost(link);
  if (host.contains('whatsapp')) return 'WhatsApp';
  if (host == 'm.me' ||
      host.contains('messenger') ||
      host.contains('facebook')) {
    return 'Messenger';
  }
  if (host == 't.me' || host.contains('telegram')) return 'Telegram';
  if (host.contains('discord')) return 'Discord';
  if (host.contains('slack')) return 'Slack';
  return host;
}

/// The site of a link, without "www.".
String linkHost(String link) {
  final host = Uri.tryParse(link)?.host.toLowerCase() ?? '';
  return host.startsWith('www.') ? host.substring(4) : host;
}
