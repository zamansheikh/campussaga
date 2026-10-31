import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/di.dart';
import '../growth_text.dart';

/// For a finisher among the first who get the reward: "You're finisher #37:
/// 20 TK mobile recharge", and a mobile number field to get it. Once sent,
/// it says so; once the team sent the reward, that. Nothing for others.
class FinisherCard extends StatefulWidget {
  const FinisherCard({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<FinisherCard> createState() => _FinisherCardState();
}

class _FinisherCardState extends State<FinisherCard> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  late bool _claimed = widget.campaign.finisher?.claimed ?? false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// A Bangladeshi mobile: 01XXXXXXXXX, or with +880 / 880 in front.
  static bool validPhone(String v) {
    final digits = v.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^(\+?880)?01[3-9][0-9]{8}$').hasMatch(digits);
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await getIt<GrowthRepository>().claimFinisherReward(
        widget.campaign.id,
        _phone.text.trim(),
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
        } else if (f.code == 'INVALID_PHONE') {
          _error = l10n.finisherPhoneInvalid;
        } else {
          _error = growthErrorText(l10n, f);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.campaign.finisher;
    final reward = widget.campaign.finisherReward;
    if (me == null || !me.inReward || reward == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final onTint = cs.onPrimaryContainer;
    Widget done(String text) => Row(
      children: [
        Icon(CsIcons.checkCircle, color: cs.primary),
        const SizedBox(width: CsSpace.sm),
        Expanded(
          child: Text(
            text,
            style: context.text.bodyMedium?.copyWith(
              color: onTint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: CsSpace.lg),
      child: Material(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(CsRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CsBadgeIcon(badgeKey: 'race_finisher', size: 32),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.finisherYou(me.position),
                      style: context.text.titleMedium?.copyWith(
                        color: onTint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.sm),
              if (me.sent)
                done(l10n.finisherSent(reward.title))
              else if (_claimed)
                done(l10n.finisherClaimed(reward.title))
              else
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.finisherClaimBody(me.position, reward.title),
                        style: context.text.bodyMedium?.copyWith(color: onTint),
                      ),
                      const SizedBox(height: CsSpace.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phone,
                              enabled: !_busy,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l10n.finisherPhoneLabel,
                                isDense: true,
                              ),
                              validator: (v) => validPhone(v ?? '')
                                  ? null
                                  : l10n.finisherPhoneInvalid,
                            ),
                          ),
                          const SizedBox(width: CsSpace.sm),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FilledButton(
                              onPressed: _busy ? null : _send,
                              child: Text(l10n.finisherClaimTitle),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: CsSpace.xs),
                        Text(
                          _error!,
                          style: context.text.bodySmall?.copyWith(
                            color: cs.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
