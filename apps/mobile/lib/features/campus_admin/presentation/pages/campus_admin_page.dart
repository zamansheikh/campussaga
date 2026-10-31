import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../classes/presentation/class_format.dart';
import '../../../verification/presentation/widgets/load_view.dart';
import '../widgets/campus_admin_widgets.dart';
import 'campus_lists.dart';
import 'sections_tab.dart';
import 'students_tab.dart';

const campusAdminTabs = [
  'inbox',
  'students',
  'sections',
  'bus',
  'reports',
  'blood',
];

/// The campus admin's tools, one tab each (docs/CAMPUS_ADMINS.md §4).
class CampusAdminPage extends StatelessWidget {
  const CampusAdminPage({super.key, this.tab = 'inbox'});

  final String tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final start = campusAdminTabs.indexOf(tab).clamp(0, 5);
    return DefaultTabController(
      length: campusAdminTabs.length,
      initialIndex: start,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.campusAdminTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.caTabInbox),
              Tab(text: l10n.caTabStudents),
              Tab(text: l10n.caTabSections),
              Tab(text: l10n.caTabBusReps),
              Tab(text: l10n.caTabReports),
              Tab(text: l10n.caTabBlood),
            ],
          ),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final tabs = DefaultTabController.of(context);
              return TabBarView(
                children: [
                  InboxTab(onGoTab: tabs.animateTo),
                  const StudentsTab(),
                  const SectionsTab(),
                  const BusRepsTab(),
                  const ReportsTab(),
                  const BloodTab(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Who is waiting, what needs a look, and the latest verifications.
class InboxTab extends StatelessWidget {
  const InboxTab({super.key, required this.onGoTab});

  final ValueChanged<int> onGoTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LoadView<CampusInbox>(
      load: () => getIt<CampusAdminRepository>().inbox(),
      builder: (context, inbox, reload) => RefreshIndicator(
        onRefresh: reload,
        child: CsPage(
          children: [
            CsSection(
              title: l10n.caNeedsAttention,
              children: [
                CsRow(
                  icon: CsIcons.flag,
                  title: l10n.caReportsWaiting(inbox.reports),
                  onTap: () => onGoTab(4),
                ),
                CsRow(
                  icon: CsIcons.groups,
                  title: l10n.caSectionsNoCr(inbox.sectionsWithoutCr),
                  onTap: () => onGoTab(2),
                ),
                CsRow(
                  icon: CsIcons.blood,
                  title: l10n.caOpenBlood(inbox.openBlood),
                  onTap: () => onGoTab(5),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.caWaiting,
              action: inbox.waitingCount > inbox.waiting.length
                  ? TextButton(
                      onPressed: () => onGoTab(1),
                      child: Text(l10n.caWaitingMore(inbox.waitingCount)),
                    )
                  : null,
              children: [
                if (inbox.waiting.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(CsSpace.md),
                    child: Text(l10n.caWaitingEmpty),
                  )
                else
                  for (final s in inbox.waiting)
                    StudentTile(
                      student: s,
                      onTap: () => context.push(Routes.campusStudent(s.id)),
                    ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.caRecent,
              children: [
                if (inbox.recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(CsSpace.md),
                    child: Text(l10n.caRecentEmpty),
                  )
                else
                  for (final e in inbox.recent)
                    CsRow(
                      icon: CsIcons.verified,
                      title: e.user?.name ?? '',
                      subtitle: historyLine(context, e),
                      onTap: e.user == null
                          ? null
                          : () =>
                                context.push(Routes.campusStudent(e.user!.id)),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Vouched by Tanvir · 2 days ago", "Confirmed by CR Rafi · ...".
String historyLine(BuildContext context, VerificationEvent e) {
  final l10n = AppLocalizations.of(context);
  final who = e.actor?.name ?? '';
  final time = e.at == null ? '' : agoText(context, e.at!, appNow());
  return switch (e.method) {
    VerifiedVia.vouch => l10n.caVouchedBy(who, time),
    VerifiedVia.cr => l10n.caConfirmedByCr(who, time),
    VerifiedVia.campusAdmin => l10n.caVerifiedByAdmin(who, time),
    VerifiedVia.admin => l10n.caVerifiedByTeam(time),
    VerifiedVia.email || null => l10n.caVerifiedByEmail(time),
  };
}
