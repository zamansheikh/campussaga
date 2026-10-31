import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The extras of a course in the class details: the class chat group, the
/// Google Classroom code (tap to copy), the materials folder, the teacher's
/// email and notes. Only what the CR added shows; the CR also gets a button
/// to add or edit them ([onEdit]).
class CourseLinks extends StatelessWidget {
  const CourseLinks({super.key, required this.info, this.onEdit});

  final CourseInfo info;

  /// The CR: add or edit the links.
  final VoidCallback? onEdit;

  static final classroomUrl = Uri.parse('https://classroom.google.com/');

  void _open(BuildContext context, Uri uri) =>
      CsLinkText.onOpen?.call(context, uri);

  Future<void> _copyCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: info.classroomCode));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.courseCodeCopied)));
  }

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
    return CsSection(
      title: l10n.courseLinks,
      action: onEdit == null
          ? null
          : TextButton(onPressed: onEdit, child: Text(l10n.editAction)),
      children: [
        if (i.chatLink.isNotEmpty)
          CsRow(
            icon: CsIcons.campus,
            title: l10n.courseChat,
            subtitle: chatAppName(i.chatLink),
            trailing: const _OpenIcon(),
            showChevron: false,
            onTap: () => _open(context, Uri.parse(i.chatLink)),
          ),
        if (i.classroomCode.isNotEmpty)
          CsRow(
            icon: CsIcons.academic,
            title: l10n.courseClassroom,
            subtitle: l10n.courseCodeLine(i.classroomCode),
            showChevron: false,
            onTap: () => _copyCode(context),
            trailing: IconButton(
              tooltip: l10n.courseOpenClassroom,
              icon: const Icon(CsIcons.openExternal, size: 18),
              onPressed: () => _open(context, classroomUrl),
            ),
          ),
        if (i.materialsLink.isNotEmpty)
          CsRow(
            icon: CsIcons.folder,
            title: l10n.courseMaterials,
            subtitle: linkHost(i.materialsLink),
            trailing: const _OpenIcon(),
            showChevron: false,
            onTap: () => _open(context, Uri.parse(i.materialsLink)),
          ),
        if (i.teacherEmail.isNotEmpty)
          CsRow(
            icon: CsIcons.email,
            title: l10n.courseTeacherEmail,
            subtitle: i.teacherEmail,
            showChevron: false,
            onTap: () =>
                _open(context, Uri(scheme: 'mailto', path: i.teacherEmail)),
          ),
        if (i.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.md,
              CsSpace.sm + 4,
              CsSpace.md,
              CsSpace.sm + 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CsIcons.note, size: 20, color: context.cs.textSecondary),
                const SizedBox(width: CsSpace.sm + 4),
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

/// The "opens elsewhere" mark, in the same place as the Classroom row's
/// open button.
class _OpenIcon extends StatelessWidget {
  const _OpenIcon();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 48, child: Icon(CsIcons.openExternal, size: 18));
}
