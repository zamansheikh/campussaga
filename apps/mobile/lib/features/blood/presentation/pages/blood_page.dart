import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/clock.dart';
import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../blood_cubit.dart';
import '../blood_format.dart';
import '../widgets/blood_widgets.dart';

/// Blood donation: the student's donor card, open requests at the
/// university (urgent first), and their own requests.
class BloodPage extends StatelessWidget {
  const BloodPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BloodCubit(getIt<BloodRepository>())..load(),
    child: const _BloodView(),
  );
}

class _BloodView extends StatelessWidget {
  const _BloodView();

  Future<void> _open(BuildContext context, BloodRequest r) async {
    final cubit = context.read<BloodCubit>();
    final changed = await context.push<BloodRequest>(Routes.bloodRequest(r.id));
    if (changed != null) cubit.updated(changed);
  }

  Future<void> _newRequest(BuildContext context) async {
    final cubit = context.read<BloodCubit>();
    await context.push(Routes.bloodNew);
    unawaited(cubit.load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BloodCubit>();
    final s = context.watch<BloodCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bloodTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: CsBloodBadge.color,
        foregroundColor: Colors.white,
        onPressed: () => _newRequest(context),
        icon: const Icon(CsIcons.bloodFill),
        label: Text(l10n.bloodRequestAction),
      ),
      body: RefreshIndicator(
        onRefresh: cubit.load,
        child: switch (s) {
          _ when s.loading && s.open.isEmpty && s.donor == null => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when s.failure != null && s.open.isEmpty => ListView(
            children: [
              CsEmptyState(
                icon: CsIcons.offline,
                title: bloodErrorText(context, s.failure!),
                actionLabel: l10n.tryAgain,
                onAction: cubit.load,
              ),
            ],
          ),
          _ => ListView(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.screen,
              CsSpace.sm,
              CsSpace.screen,
              96,
            ),
            children: [
              const _DonorCard(),
              const SizedBox(height: CsSpace.lg),
              CsSectionTitle(
                title: l10n.bloodRequests,
                action: s.donor == null
                    ? null
                    : FilterChip(
                        label: Text(
                          '${l10n.bloodMyGroupOnly} (${s.donor!.bloodGroup.label})',
                        ),
                        selected: s.myGroupOnly,
                        onSelected: cubit.setMyGroupOnly,
                      ),
              ),
              if (s.shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: CsSpace.lg),
                  child: CsEmptyState(
                    icon: CsIcons.blood,
                    title: l10n.bloodNoRequests,
                    message: l10n.bloodNoRequestsHint,
                  ),
                )
              else
                for (final r in s.shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CsSpace.sm),
                    child: BloodRequestCard(
                      request: r,
                      onTap: () => _open(context, r),
                    ),
                  ),
              if (s.mine.isNotEmpty) ...[
                const SizedBox(height: CsSpace.lg),
                CsSectionTitle(title: l10n.bloodMyRequests),
                for (final r in s.mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CsSpace.sm),
                    child: BloodRequestCard(
                      request: r,
                      onTap: () => _open(context, r),
                    ),
                  ),
              ],
            ],
          ),
        },
      ),
    );
  }
}

/// "Become a donor", or the donor's group, whether they can give now, and
/// how often they have.
class _DonorCard extends StatelessWidget {
  const _DonorCard();

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit(BuildContext context, Donor? current) async {
    final cubit = context.read<BloodCubit>();
    final input = await showDonorSheet(context, current: current);
    if (input == null || !context.mounted) return;
    final f = await cubit.saveDonor(input);
    if (f != null && context.mounted) {
      _snack(context, bloodErrorText(context, f));
    }
  }

  Future<void> _leave(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BloodCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.bloodLeaveDonors),
        content: Text(l10n.bloodLeaveDonorsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: dialog.cs.error),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.bloodLeaveDonors),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    final f = await cubit.leaveDonors();
    if (f != null && context.mounted) {
      _snack(context, bloodErrorText(context, f));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final cubit = context.read<BloodCubit>();
    final d = context.select((BloodCubit c) => c.state.donor);
    if (d == null) {
      return Container(
        padding: const EdgeInsets.all(CsSpace.md),
        decoration: BoxDecoration(
          color: CsBloodBadge.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CsRadius.lg),
          border: Border.all(color: CsBloodBadge.color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CsIcons.bloodFill,
                  color: CsBloodBadge.color,
                  size: 28,
                ),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: Text(
                    l10n.bloodBecomeDonor,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.xs),
            Text(l10n.bloodBecomeDonorHint, style: context.text.bodyMedium),
            const SizedBox(height: CsSpace.xs),
            Text(l10n.bloodPrivacyNote, style: context.text.bodySmall),
            const SizedBox(height: CsSpace.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: CsBloodBadge.color,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _edit(context, null),
              icon: const Icon(CsIcons.bloodFill),
              label: Text(l10n.bloodBecomeDonor),
            ),
          ],
        ),
      );
    }
    // The server sends the next date even once it has passed.
    final from = d.canDonateFrom;
    final canNow = from == null || !from.isAfter(DateUtils.dateOnly(appNow()));
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.md,
          CsSpace.md,
          CsSpace.xs,
          CsSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CsBloodBadge(label: d.bloodGroup.label, size: 60),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.bloodYourGroup, style: context.text.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        canNow
                            ? l10n.bloodCanDonateNow
                            : l10n.bloodCanDonateFrom(
                                bloodDateText(context, from),
                              ),
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: canNow
                              ? cs.statusSolved.fg
                              : cs.statusInProgress.fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.bloodDonationsCount(d.donations),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(CsIcons.more),
                  onSelected: (a) =>
                      a == 'edit' ? _edit(context, d) : _leave(context),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.bloodEditDonor),
                    ),
                    PopupMenuItem(
                      value: 'leave',
                      child: Text(
                        l10n.bloodLeaveDonors,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(right: CsSpace.sm),
              title: Text(l10n.bloodAvailable),
              subtitle: Text(l10n.bloodAvailableHint),
              value: d.available,
              onChanged: (v) async {
                final f = await cubit.setAvailable(v);
                if (f != null && context.mounted) {
                  _snack(context, bloodErrorText(context, f));
                }
              },
            ),
            if (canNow)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final f = await cubit.donatedToday();
                    if (!context.mounted) return;
                    _snack(
                      context,
                      f == null
                          ? l10n.bloodDonatedThanks
                          : bloodErrorText(context, f),
                    );
                  },
                  icon: const Icon(CsIcons.checkCircle, size: 20),
                  label: Text(l10n.bloodIDonated),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
