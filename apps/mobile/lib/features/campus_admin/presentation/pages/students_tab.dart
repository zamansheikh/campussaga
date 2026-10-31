import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../verification/presentation/verification_text.dart';
import '../../../verification/presentation/widgets/load_view.dart';
import '../widgets/campus_admin_widgets.dart';
import 'campus_admin_page.dart';

/// Search the university's students, filtered by verification, paged.
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _query = TextEditingController();
  StudentStatus _status = StudentStatus.unverified;
  final _items = <CampusStudent>[];
  StudentPage? _last;
  bool _loading = true;
  Failure? _failure;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final round = reset ? ++_round : _round;
    if (reset) {
      setState(() {
        _loading = true;
        _failure = null;
      });
    }
    final prev = reset ? null : _last;
    try {
      final page = await getIt<CampusAdminRepository>().students(
        status: _status,
        query: _query.text,
        cursor: prev?.nextCursor,
        page: prev?.nextPage,
      );
      if (!mounted || round != _round) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _last = page;
        _loading = false;
      });
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
    final labels = {
      StudentStatus.unverified: l10n.notVerified,
      StudentStatus.verified: l10n.caFilterVerified,
      StudentStatus.all: l10n.caFilterAll,
    };
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: CsPage(
        children: [
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: l10n.caSearchStudents,
              prefixIcon: const Icon(CsIcons.search),
            ),
          ),
          const SizedBox(height: CsSpace.sm),
          Wrap(
            spacing: CsSpace.sm,
            children: [
              for (final e in labels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _status == e.key,
                  onSelected: (_) {
                    setState(() => _status = e.key);
                    _load(reset: true);
                  },
                ),
            ],
          ),
          const SizedBox(height: CsSpace.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(CsSpace.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failure != null)
            Text(verificationErrorText(l10n, _failure!))
          else if (_items.isEmpty)
            CsEmptyState(icon: CsIcons.searchEmpty, title: l10n.caNoStudents)
          else ...[
            CsSection(
              children: [
                for (final s in _items)
                  StudentTile(
                    student: s,
                    onTap: () async {
                      await context.push(Routes.campusStudent(s.id));
                      if (mounted) await _load(reset: true);
                    },
                  ),
              ],
            ),
            if (_last?.hasMore ?? false) ...[
              const SizedBox(height: CsSpace.md),
              OutlinedButton(onPressed: _load, child: Text(l10n.voiceLoadMore)),
            ],
          ],
        ],
      ),
    );
  }
}

/// One student: card, actions, groups and verification history.
class CampusStudentPage extends StatelessWidget {
  const CampusStudentPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.caStudentTitle)),
      body: SafeArea(
        child: LoadView<CampusStudent>(
          load: () => getIt<CampusAdminRepository>().student(studentId),
          builder: (context, s, reload) =>
              _StudentView(student: s, reload: reload),
        ),
      ),
    );
  }
}

class _StudentView extends StatelessWidget {
  const _StudentView({required this.student, required this.reload});

  final CampusStudent student;
  final Future<void> Function() reload;

  /// Runs [call], shows [done] or the failure, and reloads.
  Future<void> _run(
    BuildContext context,
    Future<Object?> Function() call,
    String done,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      await reload();
    } on Failure catch (f) {
      messenger.showSnackBar(
        SnackBar(content: Text(verificationErrorText(l10n, f))),
      );
    }
  }

  Future<void> _unverify(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final s = student;
    if (s.emailVerified) {
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(l10n.caUnverify),
          content: Text(l10n.caEmailVerifiedNote),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      );
      return;
    }
    final reason = await askText(
      context,
      title: l10n.caUnverify,
      body: l10n.caUnverifyBody,
      label: l10n.caReasonLabel,
      action: l10n.caUnverify,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => getIt<CampusAdminRepository>().unverify(s.id, reason),
      l10n.caUnverifiedSnack,
    );
  }

  Future<void> _block(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<CampusAdminRepository>();
    if (student.vouchBlocked) {
      await _run(
        context,
        () => repo.unblockVouching(student.id),
        l10n.caUnblockedSnack,
      );
      return;
    }
    final reason = await askText(
      context,
      title: l10n.caBlockVouching,
      body: l10n.caBlockBody,
      label: l10n.caReasonLabel,
      action: l10n.caBlockVouching,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => repo.blockVouching(student.id, reason),
      l10n.caBlockedSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final s = student;
    final name = s.name.isEmpty ? l10n.unnamedStudent : s.name;
    return RefreshIndicator(
      onRefresh: reload,
      child: CsPage(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(CsSpace.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        userId: s.id,
                        name: name,
                        photoVersion: s.card.photoVersion,
                        googlePhotoUrl: s.card.googlePhotoUrl,
                        size: 60,
                      ),
                      const SizedBox(width: CsSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: context.text.titleLarge),
                            if (s.card.classLine.isNotEmpty)
                              Text(
                                s.card.classLine,
                                style: context.text.bodyMedium?.copyWith(
                                  color: cs.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CsSpace.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Wrap(
                      spacing: CsSpace.sm,
                      runSpacing: CsSpace.sm,
                      children: [
                        CsPill(
                          icon: s.verified ? CsIcons.verified : CsIcons.help,
                          label: s.verified
                              ? l10n.verifiedStudent
                              : l10n.notVerified,
                          highlight: !s.verified,
                        ),
                        CsPill(
                          icon: CsIcons.verifiedOutline,
                          label: l10n.caVouchesCount(s.vouches),
                        ),
                        if (s.vouchBlocked)
                          CsPill(
                            icon: CsIcons.blocked,
                            label: l10n.caBlockedPill,
                            highlight: true,
                          ),
                      ],
                    ),
                  ),
                  if (s.confirmedOrVouchedFor > 0) ...[
                    const SizedBox(height: CsSpace.sm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.caHelpedCount(s.confirmedOrVouchedFor),
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: CsSpace.lg),
          CsSection(
            children: [
              if (s.verified)
                CsRow(
                  icon: CsIcons.cancelClass,
                  title: l10n.caUnverify,
                  subtitle: s.emailVerified ? l10n.caEmailVerifiedNote : null,
                  destructive: !s.emailVerified,
                  onTap: () => _unverify(context),
                )
              else
                CsRow(
                  icon: CsIcons.verified,
                  title: l10n.caVerify,
                  onTap: () => _run(
                    context,
                    () => getIt<CampusAdminRepository>().verify(s.id),
                    l10n.caVerifiedSnack(name),
                  ),
                ),
              CsRow(
                icon: CsIcons.blocked,
                title: s.vouchBlocked
                    ? l10n.caUnblockVouching
                    : l10n.caBlockVouching,
                destructive: !s.vouchBlocked,
                onTap: () => _block(context),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.lg),
          CsSection(
            title: l10n.caGroups,
            children: [
              if (s.groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(CsSpace.md),
                  child: Text(l10n.caNoGroups),
                )
              else
                for (final g in s.groups)
                  CsRow(
                    icon: CsIcons.groups,
                    title: g.name,
                    trailing: g.isCr ? CsPill(label: l10n.roleCr) : null,
                    showChevron: false,
                  ),
            ],
          ),
          if (s.vouchedBy.isNotEmpty) ...[
            const SizedBox(height: CsSpace.lg),
            CsSectionTitle(title: l10n.caVouchedByList),
            Wrap(
              spacing: CsSpace.sm,
              runSpacing: CsSpace.sm,
              children: [
                for (final p in s.vouchedBy)
                  CsPill(icon: CsIcons.profile, label: p.name),
              ],
            ),
          ],
          const SizedBox(height: CsSpace.lg),
          CsSection(
            title: l10n.caHistory,
            children: [
              if (s.history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(CsSpace.md),
                  child: Text(l10n.caHistoryEmpty),
                )
              else
                for (final e in s.history)
                  CsRow(
                    icon: e.removed ? CsIcons.undo : CsIcons.history,
                    title: historyLine(context, e),
                    subtitle: e.removed
                        ? l10n.caHistoryRemoved(e.reason)
                        : null,
                    showChevron: false,
                  ),
            ],
          ),
          const SizedBox(height: CsSpace.lg),
          AskTeamRow(kind: EscalationKind.student, targetId: s.id),
        ],
      ),
    );
  }
}
