import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../bloc/my_issues_cubit.dart';
import '../voice_format.dart';
import '../voice_updates.dart';
import '../widgets/issue_list_card.dart';

/// The student's own issues, including ones under review or removed.
class MyIssuesPage extends StatelessWidget {
  const MyIssuesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MyIssuesCubit(getIt<VoiceRepository>())..load(),
    child: const _MyIssuesView(),
  );
}

class _MyIssuesView extends StatefulWidget {
  const _MyIssuesView();

  @override
  State<_MyIssuesView> createState() => _MyIssuesViewState();
}

class _MyIssuesViewState extends State<_MyIssuesView> {
  late final StreamSubscription<VoiceUpdate> _updates;

  @override
  void initState() {
    super.initState();
    _updates = voiceUpdates.stream.listen((u) {
      if (!mounted) return;
      switch (u) {
        case IssueChanged(:final card):
          context.read<MyIssuesCubit>().updated(card);
        case IssueDeleted():
          unawaited(context.read<MyIssuesCubit>().load());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_updates.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyIssuesCubit>();
    final s = context.watch<MyIssuesCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voiceMyIssues)),
      body: RefreshIndicator(
        onRefresh: cubit.load,
        child: switch (s) {
          _ when s.loading && s.items.isEmpty => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when s.failure != null && s.items.isEmpty => ListView(
            children: [
              CsEmptyState(
                icon: Icons.cloud_off_outlined,
                title: voiceErrorText(context, s.failure!),
                actionLabel: l10n.tryAgain,
                onAction: cubit.load,
              ),
            ],
          ),
          _ when s.items.isEmpty => ListView(
            children: [
              CsEmptyState(
                icon: Icons.campaign_outlined,
                title: l10n.voiceEmptyMine,
                message: l10n.voiceEmptyMineHint,
                actionLabel: l10n.voiceRaiseIssue,
                onAction: () => context.push(Routes.campusNew),
              ),
            ],
          ),
          _ => NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) unawaited(cubit.loadMore());
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(CsSpace.md),
              itemCount: s.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: CsSpace.sm),
              itemBuilder: (context, i) => IssueListCard(
                card: s.items[i],
                onTap: () => context.push(Routes.campusIssue(s.items[i].id)),
              ),
            ),
          ),
        },
      ),
    );
  }
}
