import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../verification/presentation/verification_text.dart';
import '../../../verification/presentation/widgets/load_view.dart';
import '../widgets/campus_admin_widgets.dart';

/// The university's sections; those without a CR come first.
class SectionsTab extends StatelessWidget {
  const SectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LoadView<List<CampusSection>>(
      load: () => getIt<CampusAdminRepository>().sections(),
      builder: (context, sections, reload) => RefreshIndicator(
        onRefresh: reload,
        child: CsPage(
          children: [
            if (sections.isEmpty)
              CsEmptyState(icon: CsIcons.groups, title: l10n.caNoSections)
            else
              CsSection(
                children: [
                  for (final s in sections)
                    CsRow(
                      icon: CsIcons.groups,
                      title: s.name,
                      subtitle: [
                        if (s.term.isNotEmpty) s.term,
                        l10n.membersCount(s.members),
                      ].join(' · '),
                      trailing: s.hasCr
                          ? CsPill(
                              icon: CsIcons.profile,
                              label: s.crs.length == 1
                                  ? s.crs.first.name
                                  : '${s.crs.first.name} +${s.crs.length - 1}',
                            )
                          : CsPill(
                              icon: CsIcons.warning,
                              label: l10n.caSectionNoCr,
                              highlight: true,
                            ),
                      onTap: () async {
                        await context.push(Routes.campusSection(s.id));
                        await reload();
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One section: its CRs, and its students to make CR.
class SectionPage extends StatelessWidget {
  const SectionPage({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).caTabSections)),
      body: SafeArea(
        child: LoadView<CampusSection>(
          load: () async {
            final all = await getIt<CampusAdminRepository>().sections();
            return all.firstWhere(
              (s) => s.id == sectionId,
              orElse: () =>
                  throw const NotFoundFailure(code: 'GROUP_NOT_FOUND'),
            );
          },
          builder: (context, section, reload) =>
              _SectionView(section: section, reload: reload),
        ),
      ),
    );
  }
}

class _SectionView extends StatefulWidget {
  const _SectionView({required this.section, required this.reload});

  final CampusSection section;
  final Future<void> Function() reload;

  @override
  State<_SectionView> createState() => _SectionViewState();
}

class _SectionViewState extends State<_SectionView> {
  final _query = TextEditingController();
  List<CampusStudent> _students = const [];
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
        groupId: widget.section.id,
      );
      if (!mounted || round != _round) return;
      setState(() {
        // Only this section's students.
        _students = [
          for (final s in page.items)
            if (s.groups.any((g) => g.id == widget.section.id)) s,
        ];
        _failure = null;
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

  Future<void> _change(Future<void> Function() call, String done) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      await widget.reload();
      await _search();
    } on Failure catch (f) {
      messenger.showSnackBar(
        SnackBar(content: Text(verificationErrorText(l10n, f))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final section = widget.section;
    final repo = getIt<CampusAdminRepository>();
    final crIds = {for (final c in section.crs) c.id};
    return CsPage(
      children: [
        Text(section.name, style: context.text.titleLarge),
        const SizedBox(height: CsSpace.xs),
        Text(
          l10n.caSectionHint,
          style: context.text.bodyMedium?.copyWith(
            color: context.cs.textSecondary,
          ),
        ),
        const SizedBox(height: CsSpace.lg),
        CsSection(
          title: l10n.caSectionCrs,
          children: [
            if (section.crs.isEmpty)
              CsRow(
                icon: CsIcons.warning,
                title: l10n.caSectionNoCr,
                showChevron: false,
              )
            else
              for (final c in section.crs)
                CsRow(
                  icon: CsIcons.profile,
                  title: c.name,
                  trailing: CsPill(
                    label: l10n.caRemoveCr,
                    trailing: null,
                    onTap: () => _change(
                      () => repo.removeCr(section.id, c.id),
                      l10n.caCrRemovedSnack(c.name),
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: CsSpace.lg),
        CsSectionTitle(title: l10n.caSectionStudents),
        TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: l10n.caSearchStudents,
            prefixIcon: const Icon(CsIcons.search),
          ),
        ),
        const SizedBox(height: CsSpace.md),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_failure != null)
          Text(verificationErrorText(l10n, _failure!))
        else if (_students.isEmpty)
          CsEmptyState(icon: CsIcons.searchEmpty, title: l10n.caNoStudents)
        else
          CsSection(
            children: [
              for (final s in _students)
                _SectionStudent(
                  student: s,
                  isCr: crIds.contains(s.id),
                  onToggle: () => crIds.contains(s.id)
                      ? _change(
                          () => repo.removeCr(section.id, s.id),
                          l10n.caCrRemovedSnack(s.name),
                        )
                      : _change(
                          () => repo.makeCr(section.id, s.id),
                          l10n.caCrMadeSnack(s.name),
                        ),
                ),
            ],
          ),
        const SizedBox(height: CsSpace.lg),
        AskTeamRow(kind: EscalationKind.section, targetId: section.id),
      ],
    );
  }
}

/// A student of the section with a CR badge and Make CR / Remove CR.
class _SectionStudent extends StatelessWidget {
  const _SectionStudent({
    required this.student,
    required this.isCr,
    required this.onToggle,
  });

  final CampusStudent student;
  final bool isCr;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StudentTile(
      student: student,
      isCr: isCr,
      trailing: CsPill(
        label: isCr ? l10n.caRemoveCr : l10n.makeCr,
        icon: isCr ? CsIcons.undo : CsIcons.star,
        trailing: null,
        onTap: onToggle,
      ),
    );
  }
}
