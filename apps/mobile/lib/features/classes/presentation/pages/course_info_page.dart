import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// The CR adds a course's extras: the class chat group, the Google
/// Classroom code, a materials folder, the teacher's email and notes. All
/// optional; everyone in the group sees them in the class details.
class CourseInfoPage extends StatefulWidget {
  const CourseInfoPage({
    super.key,
    required this.groupId,
    required this.courseCode,
  });

  final String groupId;
  final String courseCode;

  @override
  State<CourseInfoPage> createState() => _CourseInfoPageState();
}

class _CourseInfoPageState extends State<CourseInfoPage> {
  late final CourseInfo _old =
      context
          .read<MyClassesCubit>()
          .state
          .group(widget.groupId)
          ?.courseInfo(widget.courseCode) ??
      const CourseInfo();
  late final _chat = TextEditingController(text: _old.chatLink);
  late final _code = TextEditingController(text: _old.classroomCode);
  late final _materials = TextEditingController(text: _old.materialsLink);
  late final _email = TextEditingController(text: _old.teacherEmail);
  late final _notes = TextEditingController(text: _old.notes);
  bool _saving = false;
  bool _tried = false;

  static final _link = RegExp(
    r'^(https?://)?[^\s/]+\.[^\s/]{2,}(/\S*)?$',
    caseSensitive: false,
  );
  static final _codeRe = RegExp(r'^[A-Za-z0-9-]{3,20}$');
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  @override
  void dispose() {
    for (final c in [_chat, _code, _materials, _email, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "chat.whatsapp.com/x" → "https://chat.whatsapp.com/x".
  static String _withScheme(String v) {
    final t = v.trim();
    return t.isEmpty || t.contains('://') ? t : 'https://$t';
  }

  CourseInfo get _now => CourseInfo(
    chatLink: _withScheme(_chat.text),
    classroomCode: _code.text.trim(),
    materialsLink: _withScheme(_materials.text),
    teacherEmail: _email.text.trim(),
    notes: _notes.text.trim(),
  );

  String? _linkError(AppLocalizations l10n, String v) =>
      v.isEmpty || _link.hasMatch(v) ? null : l10n.courseLinkInvalid;

  bool get _changed {
    final n = _now;
    return n.chatLink != _old.chatLink ||
        n.classroomCode != _old.classroomCode ||
        n.materialsLink != _old.materialsLink ||
        n.teacherEmail != _old.teacherEmail.trim() ||
        n.notes != _old.notes.trim();
  }

  bool _valid(AppLocalizations l10n) {
    final n = _now;
    return _linkError(l10n, n.chatLink) == null &&
        _linkError(l10n, n.materialsLink) == null &&
        (n.classroomCode.isEmpty || _codeRe.hasMatch(n.classroomCode)) &&
        (n.teacherEmail.isEmpty || _emailRe.hasMatch(n.teacherEmail));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _tried = true);
    if (!_valid(l10n)) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      await context.read<MyClassesCubit>().setCourseInfo(
        widget.groupId,
        widget.courseCode,
        _now,
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.courseLinksSaved)));
      router.pop();
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(classErrorText(l10n, f))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = _now;
    String? shown(String? error) => _tried ? error : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseCode),
        actions: [
          CsBarButton(
            label: l10n.saveAction,
            busy: _saving,
            onPressed: _changed ? _save : null,
          ),
        ],
      ),
      body: CsPage(
        children: [
          Text(l10n.courseLinks, style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.courseLinksOptional,
            style: context.text.bodyMedium?.copyWith(
              color: context.cs.textSecondary,
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          TextField(
            controller: _chat,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.courseChat,
              hintText: l10n.courseChatHint,
              prefixIcon: const Icon(CsIcons.campus),
              errorText: shown(_linkError(l10n, n.chatLink)),
            ),
          ),
          const SizedBox(height: CsSpace.md),
          TextField(
            controller: _code,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.courseClassroomCode,
              hintText: l10n.courseClassroomCodeHint,
              prefixIcon: const Icon(CsIcons.academic),
              counterText: '',
              errorText: shown(
                n.classroomCode.isEmpty || _codeRe.hasMatch(n.classroomCode)
                    ? null
                    : l10n.courseCodeInvalid,
              ),
            ),
          ),
          const SizedBox(height: CsSpace.md),
          TextField(
            controller: _materials,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.courseMaterials,
              hintText: l10n.courseMaterialsHint,
              prefixIcon: const Icon(CsIcons.folder),
              errorText: shown(_linkError(l10n, n.materialsLink)),
            ),
          ),
          const SizedBox(height: CsSpace.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.courseTeacherEmail,
              prefixIcon: const Icon(CsIcons.email),
              errorText: shown(
                n.teacherEmail.isEmpty || _emailRe.hasMatch(n.teacherEmail)
                    ? null
                    : l10n.courseEmailInvalid,
              ),
            ),
          ),
          const SizedBox(height: CsSpace.md),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.courseNotes,
              hintText: l10n.courseNotesHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
