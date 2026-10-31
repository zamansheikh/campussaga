import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di.dart';
import '../blood_cubit.dart';
import '../blood_format.dart';
import '../widgets/blood_widgets.dart';

/// One request: what's needed, where and when, who to call; donors offer
/// to donate here, and the requester sees who did and closes it.
class BloodRequestPage extends StatelessWidget {
  const BloodRequestPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        BloodRequestCubit(getIt<BloodRepository>(), requestId)..load(),
    child: const _RequestView(),
  );
}

class _RequestView extends StatelessWidget {
  const _RequestView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BloodRequestCubit>();
    final s = context.watch<BloodRequestCubit>().state;
    final r = s.request;
    return PopScope(
      canPop: false,
      // Hand the latest copy back to the list.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(r);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bloodTitle),
          actions: [
            if (r != null)
              IconButton(
                tooltip: l10n.campusShare,
                icon: const Icon(CsIcons.share),
                onPressed: () {
                  final box = context.findRenderObject() as RenderBox?;
                  SharePlus.instance.share(
                    ShareParams(
                      text: bloodShareText(context, r),
                      sharePositionOrigin: box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                },
              ),
          ],
        ),
        body: switch (r) {
          null when s.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          null => CsEmptyState(
            icon: CsIcons.blood,
            title: bloodErrorText(
              context,
              s.failure ?? const UnexpectedFailure(),
            ),
            actionLabel: l10n.tryAgain,
            onAction: cubit.load,
          ),
          final r => RefreshIndicator(
            onRefresh: cubit.load,
            child: CsPage(children: [_Body(request: r)]),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.request});

  final BloodRequest request;

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  void _call(BuildContext context, String phone) =>
      CsLinkText.onOpen?.call(context, Uri(scheme: 'tel', path: phone));

  Future<void> _copy(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) _snack(context, l10n.bloodPhoneCopied);
  }

  /// "I can donate": a donor profile first if needed, then confirm the
  /// phone that goes to the requester.
  Future<void> _offer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BloodRequestCubit>();
    var donor = cubit.state.donor;
    if (donor == null) {
      final input = await showDonorSheet(context);
      if (input == null || !context.mounted) return;
      try {
        donor = await getIt<BloodRepository>().saveDonor(input);
        cubit.donorSaved(donor);
      } on Failure catch (f) {
        if (context.mounted) _snack(context, bloodErrorText(context, f));
        return;
      }
      if (!context.mounted) return;
    }
    final phone = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OfferSheet(request: request, donor: donor!),
    );
    if (phone == null || !context.mounted) return;
    final f = await cubit.respond(phone);
    if (!context.mounted) return;
    _snack(
      context,
      f == null
          ? l10n.bloodResponded(request.contactName)
          : bloodErrorText(context, f),
    );
  }

  Future<void> _finish(BuildContext context, {required bool fulfilled}) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BloodRequestCubit>();
    if (!fulfilled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.bloodCancelRequest),
          content: Text(l10n.bloodCancelConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: dialog.cs.error),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.bloodCancelRequest),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    final f = await cubit.finish(fulfilled: fulfilled);
    if (!context.mounted) return;
    if (f != null) {
      _snack(context, bloodErrorText(context, f));
    } else if (fulfilled) {
      _snack(context, l10n.bloodClosedThanks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final r = request;
    final s = context.watch<BloodRequestCubit>().state;
    final donor = s.donor;
    final status = bloodStatusText(l10n, r.status);
    final muted = context.text.bodySmall?.copyWith(color: cs.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CsBloodBadge(label: r.bloodGroup.label, size: 72),
            const SizedBox(width: CsSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bloodNeededTitle(r.bloodGroup.label),
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      CsBadge(
                        label: l10n.bloodUnits(r.units),
                        tone: CsBadgeTone.neutral,
                      ),
                      if (r.urgent && r.isOpen)
                        CsBadge(
                          label: l10n.bloodUrgent,
                          tone: CsBadgeTone.danger,
                        ),
                      if (status.isNotEmpty)
                        CsBadge(label: status, tone: CsBadgeTone.neutral),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: CsSpace.lg),
        CsSection(
          children: [
            CsRow(
              icon: CsIcons.place,
              title: r.hospital,
              subtitle: r.area.isEmpty ? null : r.area,
              showChevron: false,
            ),
            CsRow(
              icon: CsIcons.time,
              title: bloodWhenText(context, r.neededBy),
              subtitle: l10n.bloodWhen,
              showChevron: false,
            ),
            CsRow(
              icon: CsIcons.profile,
              title: r.contactName,
              subtitle: r.contactPhone,
              showChevron: false,
              onTap: () => _copy(context, r.contactPhone),
              trailing: r.mine
                  ? null
                  : IconButton.filled(
                      tooltip: l10n.bloodCall,
                      style: IconButton.styleFrom(
                        backgroundColor: cs.statusSolved.bg,
                        foregroundColor: cs.statusSolved.fg,
                      ),
                      onPressed: () => _call(context, r.contactPhone),
                      icon: const Icon(CsIcons.call),
                    ),
            ),
          ],
        ),
        if (r.note.isNotEmpty) ...[
          const SizedBox(height: CsSpace.md),
          Container(
            padding: const EdgeInsets.all(CsSpace.sm + 4),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(CsRadius.md),
            ),
            child: CsLinkText(
              r.note,
              style: context.text.bodyMedium,
              selectable: true,
            ),
          ),
        ],
        const SizedBox(height: CsSpace.md),
        Text(l10n.bloodCompatible(compatibleText(r.bloodGroup)), style: muted),
        if (r.matchingDonors > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.bloodMatching(r.matchingDonors, r.bloodGroup.label),
              style: muted,
            ),
          ),
        const SizedBox(height: CsSpace.lg),
        if (r.mine) ..._mine(context, r) else ..._donor(context, r, donor),
      ],
    );
  }

  /// The requester: who can help, and closing the request.
  List<Widget> _mine(BuildContext context, BloodRequest r) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final busy = context.select((BloodRequestCubit c) => c.state.busy);
    return [
      if (r.notified > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: CsSpace.sm),
          child: Text(
            l10n.bloodNotified(r.notified, r.bloodGroup.label),
            style: context.text.bodyMedium,
          ),
        ),
      CsSectionTitle(title: l10n.bloodResponses(r.responses.length)),
      if (r.responses.isNotEmpty)
        CsSection(
          children: [
            for (final x in r.responses)
              CsRow(
                icon: CsIcons.bloodFill,
                title: x.name,
                subtitle: [
                  if (x.bloodGroup != null) x.bloodGroup!.label,
                  x.phone,
                ].join(' · '),
                showChevron: false,
                trailing: IconButton.filled(
                  tooltip: l10n.bloodCall,
                  style: IconButton.styleFrom(
                    backgroundColor: cs.statusSolved.bg,
                    foregroundColor: cs.statusSolved.fg,
                  ),
                  onPressed: () => _call(context, x.phone),
                  icon: const Icon(CsIcons.call),
                ),
              ),
          ],
        ),
      if (r.isOpen) ...[
        const SizedBox(height: CsSpace.lg),
        FilledButton.icon(
          onPressed: busy ? null : () => _finish(context, fulfilled: true),
          icon: const Icon(CsIcons.checkCircle),
          label: Text(l10n.bloodGotBlood),
        ),
        const SizedBox(height: CsSpace.sm),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: busy ? null : () => _finish(context, fulfilled: false),
          child: Text(l10n.bloodCancelRequest),
        ),
      ],
    ];
  }

  /// Everyone else: "I can donate", or what they offered.
  List<Widget> _donor(BuildContext context, BloodRequest r, Donor? donor) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final cubit = context.read<BloodRequestCubit>();
    final busy = context.select((BloodRequestCubit c) => c.state.busy);
    if (!r.isOpen) return const [];
    if (r.responded) {
      return [
        Container(
          padding: const EdgeInsets.all(CsSpace.md),
          decoration: BoxDecoration(
            color: cs.statusSolved.bg,
            borderRadius: BorderRadius.circular(CsRadius.md),
          ),
          child: Row(
            children: [
              Icon(CsIcons.checkCircle, color: cs.statusSolved.fg),
              const SizedBox(width: CsSpace.sm),
              Expanded(
                child: Text(
                  l10n.bloodYouOffered,
                  style: context.text.titleSmall?.copyWith(
                    color: cs.statusSolved.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CsSpace.sm),
        FilledButton.icon(
          onPressed: () => _call(context, r.contactPhone),
          icon: const Icon(CsIcons.call),
          label: Text('${l10n.bloodCall} ${r.contactName}'),
        ),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  final f = await cubit.withdraw();
                  if (f != null && context.mounted) {
                    _snack(context, bloodErrorText(context, f));
                  }
                },
          child: Text(l10n.bloodWithdraw),
        ),
      ];
    }
    return [
      if (donor != null && donor.bloodGroup != r.bloodGroup)
        Padding(
          padding: const EdgeInsets.only(bottom: CsSpace.sm),
          child: Text(
            l10n.bloodNotYourGroup(r.bloodGroup.label, donor.bloodGroup.label),
            style: context.text.bodySmall?.copyWith(
              color: cs.statusInProgress.fg,
            ),
          ),
        ),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: CsBloodBadge.color,
          foregroundColor: Colors.white,
        ),
        onPressed: busy ? null : () => _offer(context),
        icon: const Icon(CsIcons.bloodFill),
        label: Text(l10n.bloodICanDonate),
      ),
    ];
  }
}

/// Confirm before the phone number goes to the requester.
class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.request, required this.donor});

  final BloodRequest request;
  final Donor donor;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  late final _phone = TextEditingController(text: widget.donor.phone);
  bool _tried = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = cleanPhone(_phone.text);
    final ok = phone != null && phone.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CsSpace.lg,
          0,
          CsSpace.lg,
          CsSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CsBloodBadge(label: widget.donor.bloodGroup.label, size: 40),
                const SizedBox(width: CsSpace.sm + 4),
                Expanded(
                  child: Text(
                    l10n.bloodRespondTitle,
                    style: context.text.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.sm),
            Text(
              l10n.bloodRespondBody(widget.request.contactName),
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: CsSpace.md),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofocus: widget.donor.phone.isEmpty,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.bloodPhone,
                hintText: '01712345678',
                prefixIcon: const Icon(CsIcons.call),
                errorText: _tried && !ok ? l10n.bloodPhoneInvalid : null,
              ),
            ),
            const SizedBox(height: CsSpace.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: CsBloodBadge.color,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => _tried = true);
                if (ok) Navigator.of(context).pop(phone);
              },
              icon: const Icon(CsIcons.send),
              label: Text(l10n.bloodRespondSend),
            ),
          ],
        ),
      ),
    );
  }
}
