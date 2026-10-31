import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// "Get verified" for students who are not verified (Profile and Today).
/// Nothing for verified students.
class VerifyBanner extends StatelessWidget {
  const VerifyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final verified = context.select((AuthBloc b) => b.state.user?.verified);
    if (verified ?? true) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.lg),
      child: Material(
        color: cs.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.verify),
          child: Padding(
            padding: const EdgeInsets.all(CsSpace.md),
            child: Row(
              children: [
                Icon(CsIcons.verifiedOutline, color: cs.onPrimaryContainer),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.verifyBannerTitle,
                        style: context.text.titleSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: CsSpace.xxs),
                      Text(
                        l10n.verifyBannerBody,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CsIcons.chevronRight, color: cs.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
