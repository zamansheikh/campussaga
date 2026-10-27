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

  bool get _editing => _group != null;

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
                prefixIcon: const Icon(Icons.apartment_rounded),
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
                      prefixIcon: const Icon(Icons.groups_outlined),
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
                prefixIcon: const Icon(Icons.date_range_outlined),
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
