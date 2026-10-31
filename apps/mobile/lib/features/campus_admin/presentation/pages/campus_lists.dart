import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../classes/presentation/class_format.dart';
import '../../../verification/presentation/verification_text.dart';
import '../../../verification/presentation/widgets/load_view.dart';
import '../../../voice/presentation/voice_format.dart';
import '../widgets/campus_admin_widgets.dart';

/// Shows [call]'s failure in plain words (or [done] when it worked).
Future<bool> _attempt(
  BuildContext context,
  Future<void> Function() call, {
  String? done,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await call();
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return true;
  } on Failure catch (f) {
    messenger.showSnackBar(
      SnackBar(content: Text(verificationErrorText(l10n, f))),
    );
    return false;
  }
}

/// The university's transport reps: remove, or add a student.
class BusRepsTab extends StatelessWidget {
  const BusRepsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<CampusAdminRepository>();
    return LoadView<List<BusRep>>(
      load: repo.busReps,
      builder: (context, reps, reload) => RefreshIndicator(
        onRefresh: reload,
        child: CsPage(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CsPill(
                icon: CsIcons.addCircle,
                label: l10n.caAddBusRep,
                trailing: null,
                onTap: () async {
                  final s = await pickStudent(context);
                  if (s == null || !context.mounted) return;
                  if (await _attempt(context, () => repo.addBusRep(s.id))) {
                    await reload();
                  }
                },
              ),
            ),
            const SizedBox(height: CsSpace.md),
            if (reps.isEmpty)
              CsEmptyState(icon: CsIcons.bus, title: l10n.caBusRepsEmpty)
            else
              CsSection(
                children: [
                  for (final r in reps)
                    CsRow(
                      icon: CsIcons.bus,
                      title: r.name.isEmpty ? l10n.unnamedStudent : r.name,
                      trailing: CsPill(
                        label: l10n.caRemove,
                        trailing: null,
                        onTap: () async {
                          if (await _attempt(
                            context,
                            () => repo.removeBusRep(r.userId),
                          )) {
                            await reload();
                          }
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Reported posts and comments: hide, restore or dismiss; tap to read.
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<CampusAdminRepository>();
    return LoadView<List<CampusReport>>(
      load: repo.reports,
      builder: (context, reports, reload) => RefreshIndicator(
        onRefresh: reload,
        child: CsPage(
          children: [
            if (reports.isEmpty)
              CsEmptyState(icon: CsIcons.flag, title: l10n.caReportsEmpty)
            else
              for (final r in reports) ...[
                _ReportCard(
                  report: r,
                  onAction: (a) async {
                    if (await _attempt(
                      context,
                      () => repo.report(r.kind, r.id, a),
                    )) {
                      await reload();
                    }
                  },
                ),
                const SizedBox(height: CsSpace.md),
              ],
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onAction});

  final CampusReport report;
  final ValueChanged<ReportAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = report;
    final reasons = <String>{
      for (final w in r.reasons)
        for (final reason in ReportReason.values)
          if (reason.wire == w) reportReasonLabel(l10n, reason),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.campusIssue(r.issueId)),
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: CsSpace.sm,
                runSpacing: CsSpace.sm,
                children: [
                  CsPill(
                    icon: r.kind == ReportKind.comment
                        ? CsIcons.comment
                        : CsIcons.post,
                    label: r.kind == ReportKind.comment
                        ? l10n.caReportComment
                        : l10n.caReportPost,
                  ),
                  CsPill(
                    icon: CsIcons.flag,
                    label: l10n.caReportCount(r.reports),
                    highlight: true,
                  ),
                  if (r.hidden)
                    CsPill(icon: CsIcons.hidden, label: l10n.caReportHidden),
                  for (final reason in reasons) CsPill(label: reason),
                ],
              ),
              const SizedBox(height: CsSpace.sm),
              Text(
                r.excerpt,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
              if (r.createdAt != null) ...[
                const SizedBox(height: CsSpace.xs),
                Text(
                  agoText(context, r.createdAt!, appNow()),
                  style: context.text.bodySmall,
                ),
              ],
              const SizedBox(height: CsSpace.sm),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () => onAction(
                      r.hidden ? ReportAction.restore : ReportAction.hide,
                    ),
                    child: Text(
                      r.hidden ? l10n.caReportRestore : l10n.caReportHide,
                    ),
                  ),
                  const SizedBox(width: CsSpace.sm),
                  TextButton(
                    onPressed: () => onAction(ReportAction.dismiss),
                    child: Text(l10n.caReportDismiss),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Open blood requests of the university: close one (optional reason).
class BloodTab extends StatelessWidget {
  const BloodTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<CampusAdminRepository>();
    return LoadView<List<CampusBloodRequest>>(
      load: repo.blood,
      builder: (context, items, reload) => RefreshIndicator(
        onRefresh: reload,
        child: CsPage(
          children: [
            if (items.isEmpty)
              CsEmptyState(icon: CsIcons.blood, title: l10n.caBloodEmpty)
            else
              CsSection(
                children: [
                  for (final b in items)
                    CsRow(
                      icon: CsIcons.blood,
                      title: '${b.bloodGroup} · ${b.hospital}',
                      subtitle: [
                        if (b.area.isNotEmpty) b.area,
                        if (b.requesterName.isNotEmpty) b.requesterName,
                      ].join(' · '),
                      trailing: CsPill(
                        label: l10n.caBloodClose,
                        trailing: null,
                        onTap: () async {
                          final reason = await askText(
                            context,
                            title: l10n.caBloodCloseTitle,
                            label: l10n.caBloodCloseReason,
                            action: l10n.caBloodClose,
                            required: false,
                          );
                          if (reason == null || !context.mounted) return;
                          if (await _attempt(
                            context,
                            () => repo.closeBlood(b.id, reason: reason),
                            done: l10n.caBloodClosedSnack,
                          )) {
                            await reload();
                          }
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
