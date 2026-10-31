import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../blood_format.dart';

/// On Today, for a donor who can give now: open requests for their blood
/// group at the university (at most two), each opening the request.
/// Nothing shows otherwise (or when it can't load).
class BloodNeededCard extends StatefulWidget {
  const BloodNeededCard({super.key});

  @override
  State<BloodNeededCard> createState() => _BloodNeededCardState();
}

class _BloodNeededCardState extends State<BloodNeededCard> {
  List<BloodRequest> _needed = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = getIt<BloodRepository>();
    try {
      final donor = await repo.me();
      if (donor == null || !donor.eligible) {
        if (mounted) setState(() => _needed = const []);
        return;
      }
      final list = await repo.requests(group: donor.bloodGroup);
      if (!mounted) return;
      setState(
        () => _needed = [
          for (final r in list.items)
            if (r.isOpen && !r.mine && !r.responded) r,
        ].take(2).toList(),
      );
    } on Failure {
      // Only a nudge: say nothing.
    }
  }

  Future<void> _open(BloodRequest r) async {
    await context.push(Routes.bloodRequest(r.id));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_needed.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.md),
      child: Column(
        children: [
          for (final r in _needed)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.sm),
              child: Material(
                color: CsBloodBadge.color,
                borderRadius: BorderRadius.circular(CsRadius.lg),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(r),
                  child: Padding(
                    padding: const EdgeInsets.all(CsSpace.md),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            r.bloodGroup.label,
                            style: context.text.titleMedium?.copyWith(
                              color: CsBloodBadge.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: CsSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  l10n.bloodNeededTitle(r.bloodGroup.label),
                                  if (r.urgent) l10n.bloodUrgent,
                                ].join(' · '),
                                style: context.text.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${r.hospital} · ${bloodWhenText(context, r.neededBy)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(CsIcons.chevronRight, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
