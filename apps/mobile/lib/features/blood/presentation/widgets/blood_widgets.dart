import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/clock.dart';
import '../blood_format.dart';

/// The eight groups as a 4 × 2 grid of big buttons.
class BloodGroupPicker extends StatelessWidget {
  const BloodGroupPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BloodGroup? selected;
  final ValueChanged<BloodGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      // No safe-area padding inside sheets.
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: CsSpace.sm,
      crossAxisSpacing: CsSpace.sm,
      childAspectRatio: 1.6,
      children: [
        for (final g in BloodGroup.values)
          Semantics(
            button: true,
            selected: g == selected,
            child: Material(
              color: g == selected ? CsBloodBadge.color : cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CsRadius.md),
                side: BorderSide(
                  color: g == selected ? CsBloodBadge.color : cs.border,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(g),
                child: Center(
                  child: Text(
                    g.label,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: g == selected ? Colors.white : cs.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A request in a list: group, where, when, and how many can help.
class BloodRequestCard extends StatelessWidget {
  const BloodRequestCard({super.key, required this.request, this.onTap});

  final BloodRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final r = request;
    final muted = context.text.bodySmall?.copyWith(color: cs.textSecondary);
    final status = bloodStatusText(l10n, r.status);
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(
          color: r.urgent && r.isOpen
              ? CsBloodBadge.color.withValues(alpha: 0.6)
              : cs.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Row(
            children: [
              CsBloodBadge(label: r.bloodGroup.label, size: 48),
              const SizedBox(width: CsSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            r.hospital,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (r.urgent && r.isOpen) ...[
                          const SizedBox(width: 6),
                          CsBadge(
                            label: l10n.bloodUrgent,
                            tone: CsBadgeTone.danger,
                          ),
                        ],
                        if (status.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          CsBadge(label: status, tone: CsBadgeTone.neutral),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        bloodWhenText(context, r.neededBy),
                        l10n.bloodUnits(r.units),
                        if (r.area.isNotEmpty) r.area,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                    if (r.responseCount > 0 || r.mine)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          l10n.bloodResponses(r.responseCount),
                          style: muted?.copyWith(
                            color: r.responseCount > 0 ? cs.primary : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(CsIcons.chevronRight, color: cs.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Become a donor, or edit the donor profile: group, last donation, phone,
/// available. Answers what to save, or null.
Future<DonorInput?> showDonorSheet(BuildContext context, {Donor? current}) =>
    showModalBottomSheet<DonorInput>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DonorSheet(current: current),
    );

class _DonorSheet extends StatefulWidget {
  const _DonorSheet({this.current});

  final Donor? current;

  @override
  State<_DonorSheet> createState() => _DonorSheetState();
}

class _DonorSheetState extends State<_DonorSheet> {
  late BloodGroup? _group = widget.current?.bloodGroup;
  late DateTime? _last = widget.current?.lastDonated;
  late bool _available = widget.current?.available ?? true;
  late final _phone = TextEditingController(text: widget.current?.phone);
  bool _tried = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickLast() async {
    final today = DateUtils.dateOnly(appNow());
    final d = await showDatePicker(
      context: context,
      initialDate: _last ?? today,
      firstDate: DateTime(today.year - 10),
      lastDate: today,
    );
    if (d != null) setState(() => _last = d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = cleanPhone(_phone.text);
    final phoneOk = phone != null;
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
            Text(
              widget.current == null
                  ? l10n.bloodBecomeDonor
                  : l10n.bloodEditDonor,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: CsSpace.xs),
            Text(l10n.bloodPrivacyNote, style: context.text.bodySmall),
            const SizedBox(height: CsSpace.md),
            Text(l10n.bloodYourGroup, style: context.text.titleSmall),
            const SizedBox(height: CsSpace.sm),
            BloodGroupPicker(
              selected: _group,
              onSelected: (g) => setState(() => _group = g),
            ),
            const SizedBox(height: CsSpace.md),
            CsRow(
              icon: CsIcons.date,
              title: l10n.bloodLastDonated,
              subtitle: _last == null
                  ? l10n.bloodNeverDonated
                  : bloodDateText(context, _last!),
              onTap: _pickLast,
              trailing: _last == null
                  ? null
                  : IconButton(
                      tooltip: l10n.bloodNeverDonated,
                      icon: const Icon(CsIcons.close, size: 18),
                      onPressed: () => setState(() => _last = null),
                    ),
            ),
            const SizedBox(height: CsSpace.sm),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.bloodPhone,
                hintText: '01712345678',
                prefixIcon: const Icon(CsIcons.call),
                helperText: l10n.bloodPhoneHint,
                helperMaxLines: 2,
                errorText: _tried && !phoneOk ? l10n.bloodPhoneInvalid : null,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.bloodAvailable),
              subtitle: Text(l10n.bloodAvailableHint),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: CsSpace.sm),
            FilledButton(
              onPressed: _group == null
                  ? null
                  : () {
                      setState(() => _tried = true);
                      if (!phoneOk) return;
                      Navigator.of(context).pop(
                        DonorInput(
                          bloodGroup: _group!,
                          available: _available,
                          phone: phone,
                          lastDonated: _last,
                        ),
                      );
                    },
              child: Text(l10n.bloodSaveDonor),
            ),
          ],
        ),
      ),
    );
  }
}
