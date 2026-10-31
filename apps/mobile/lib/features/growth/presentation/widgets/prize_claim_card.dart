import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';
import '../growth_text.dart';

/// "You won!": the prize, and the form for where to deliver it (full name,
/// phone, address, a note). Once sent, or already sent before, it says
/// "We'll contact you" instead.
class PrizeClaimCard extends StatefulWidget {
  const PrizeClaimCard({
    super.key,
    required this.campaignId,
    required this.win,
  });

  final String campaignId;
  final CampaignWin win;

  @override
  State<PrizeClaimCard> createState() => _PrizeClaimCardState();
}

class _PrizeClaimCardState extends State<PrizeClaimCard> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  late bool _claimed = widget.win.claimed;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  /// At least 10 digits, nothing but digits, spaces, + - ( ).
  static bool _validPhone(String v) {
    final t = v.trim();
    if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(t)) return false;
    return t.replaceAll(RegExp('[^0-9]'), '').length >= 10;
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await getIt<GrowthRepository>().claimPrize(
        widget.campaignId,
        PrizeClaim(
          fullName: _name.text,
          phone: _phone.text,
          address: _address.text,
          note: _note.text,
        ),
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _claimed = true;
        });
      }
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (f.code == 'ALREADY_CLAIMED') {
          _claimed = true;
        } else {
          _error = growthErrorText(l10n, f);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final onTint = cs.onPrimaryContainer;
    return Material(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(CsRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(CsSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(CsIcons.trophy, color: onTint),
                const SizedBox(width: CsSpace.sm),
                Expanded(
                  child: Text(
                    l10n.winTitle,
                    style: context.text.titleLarge?.copyWith(color: onTint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.xs),
            Text(
              l10n.winPrize(widget.win.rank, widget.win.prize),
              style: context.text.titleSmall?.copyWith(color: onTint),
            ),
            const SizedBox(height: CsSpace.md),
            if (_claimed) ...[
              Row(
                children: [
                  Icon(CsIcons.checkCircle, color: cs.primary),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.claimDone,
                      style: context.text.titleMedium?.copyWith(color: onTint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.xs),
              Text(
                l10n.claimDoneBody,
                style: context.text.bodyMedium?.copyWith(color: onTint),
              ),
            ] else
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.claimIntro,
                      style: context.text.bodyMedium?.copyWith(color: onTint),
                    ),
                    const SizedBox(height: CsSpace.md),
                    TextFormField(
                      controller: _name,
                      enabled: !_busy,
                      maxLength: 80,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.claimFullName,
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? l10n.claimNameRequired
                          : null,
                    ),
                    TextFormField(
                      controller: _phone,
                      enabled: !_busy,
                      maxLength: 20,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.claimPhone),
                      validator: (v) =>
                          _validPhone(v ?? '') ? null : l10n.claimPhoneInvalid,
                    ),
                    TextFormField(
                      controller: _address,
                      enabled: !_busy,
                      maxLength: 300,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.claimAddress),
                      validator: (v) => (v?.trim().length ?? 0) < 6
                          ? l10n.claimAddressRequired
                          : null,
                    ),
                    TextFormField(
                      controller: _note,
                      enabled: !_busy,
                      maxLength: 300,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l10n.claimNote),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: CsSpace.sm),
                      Text(
                        _error!,
                        style: context.text.bodyMedium?.copyWith(
                          color: cs.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: CsSpace.md),
                    FilledButton(
                      onPressed: _busy ? null : _send,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.claimSend),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
