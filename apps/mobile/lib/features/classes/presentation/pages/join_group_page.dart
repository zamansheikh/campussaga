import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../auth/presentation/widgets/notice_banner.dart';
import '../bloc/my_classes_cubit.dart';
import '../class_format.dart';

/// Enter the CR's 6-letter code, see which group it is, then join.
class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _code = TextEditingController();
  GroupPreview? _preview;
  Failure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _lookUp(String code) async {
    setState(() {
      _busy = true;
      _failure = null;
      _preview = null;
    });
    try {
      final p = await context.read<MyClassesCubit>().preview(code);
      if (mounted) setState(() => _preview = p);
    } on Failure catch (f) {
      if (!mounted) return;
      _code.clear();
      setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final g = await context.read<MyClassesCubit>().join(_code.text);
      if (mounted) context.pushReplacement(Routes.group(g.id));
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final p = _preview;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: CsPage(
          padding: const EdgeInsets.fromLTRB(
            CsSpace.lg,
            CsSpace.sm,
            CsSpace.lg,
            CsSpace.lg,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(CsRadius.md + 2),
                ),
                child: Icon(CsIcons.key, color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: CsSpace.lg),
            Text(l10n.joinTitle, style: context.text.headlineSmall),
            const SizedBox(height: CsSpace.sm),
            Text(
              l10n.joinSubtitle,
              style: context.text.bodyLarge?.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: CsSpace.lg),
            CsCodeField(
              controller: _code,
              letters: true,
              enabled: !_busy,
              hasError: _failure != null,
              semanticLabel: l10n.joinCodeLabel,
              onCompleted: _lookUp,
            ),
            if (_busy && p == null) ...[
              const SizedBox(height: CsSpace.lg),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_failure != null) ...[
              const SizedBox(height: CsSpace.md),
              NoticeBanner(text: classErrorText(l10n, _failure!)),
            ],
            if (p != null) ...[
              const SizedBox(height: CsSpace.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(CsSpace.md + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: context.text.titleLarge),
                      const SizedBox(height: 2),
                      Text(p.semester, style: context.text.bodyMedium),
                      const SizedBox(height: CsSpace.md),
                      Wrap(
                        spacing: CsSpace.sm,
                        runSpacing: CsSpace.sm,
                        children: [
                          CsBadge(
                            icon: CsIcons.members,
                            label: l10n.membersCount(p.memberCount),
                            tone: CsBadgeTone.neutral,
                          ),
                          CsBadge(
                            icon: CsIcons.routineNote,
                            label: l10n.classesCount(p.classCount),
                            tone: CsBadgeTone.neutral,
                          ),
                        ],
                      ),
                      if (p.isMember) ...[
                        const SizedBox(height: CsSpace.md),
                        CsBadge(
                          icon: CsIcons.checkCircle,
                          label: l10n.alreadyMember,
                          tone: CsBadgeTone.success,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CsSpace.lg),
              FilledButton(
                onPressed: _busy ? null : _join,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(p.isMember ? l10n.openGroup : l10n.joinAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
