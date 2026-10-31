import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../verification_text.dart';
import '../widgets/load_view.dart';

/// The ways to get verified: the university email, the section's CR, or
/// two verified classmates (docs/CAMPUS_ADMINS.md §4).
class GetVerifiedPage extends StatelessWidget {
  const GetVerifiedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyGetTitle)),
      body: SafeArea(
        child: LoadView<MyVerification>(
          load: () async {
            final auth = context.read<AuthBloc>();
            final mine = await getIt<VerificationRepository>().mine();
            // Verified since the last time (a classmate, a CR): the rest of
            // the app should know.
            if (mine.verified && !(auth.state.user?.verified ?? true)) {
              auth.add(const AuthRefreshRequested());
            }
            return mine;
          },
          builder: (context, mine, reload) => mine.verified
              ? _Done(via: mine.via)
              : _Ways(mine: mine, reload: reload),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.via});

  final VerifiedVia? via;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CsEmptyState(
      icon: CsIcons.verified,
      title: l10n.verifyDoneTitle,
      message: verifiedViaText(l10n, via),
      actionLabel: l10n.gotIt,
      onAction: () => context.pop(),
    );
  }
}

class _Ways extends StatelessWidget {
  const _Ways({required this.mine, required this.reload});

  final MyVerification mine;
  final Future<void> Function() reload;

  void _share(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final uni =
        context.read<AuthBloc>().state.user?.university?.localName(lang) ?? '';
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: l10n.verifyShareText(uni, mine.link),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return RefreshIndicator(
      onRefresh: reload,
      child: CsPage(
        children: [
          Text(
            l10n.verifyIntro,
            style: context.text.bodyLarge?.copyWith(color: cs.textSecondary),
          ),
          const SizedBox(height: CsSpace.lg),
          if (mine.emailPossible) ...[
            CsSection(
              title: l10n.verifyViaEmail,
              children: [
                CsRow(
                  icon: CsIcons.email,
                  title: l10n.verifyViaEmail,
                  subtitle: l10n.verifyViaEmailHint,
                  onTap: () async {
                    await context.push(Routes.verifyEmail);
                    await reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
          ],
          CsSection(
            title: l10n.verifyAskCr,
            children: [
              if (mine.crs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(CsSpace.md),
                  child: Text(l10n.verifyNoCr, style: context.text.bodyMedium),
                )
              else
                for (final cr in mine.crs)
                  CsRow(
                    icon: CsIcons.members,
                    title: l10n.verifyCrLine(cr.crName, cr.groupName),
                    subtitle: l10n.verifyAskCrHint,
                    onTap: () => context.push(Routes.group(cr.groupId)),
                  ),
            ],
          ),
          const SizedBox(height: CsSpace.lg),
          CsSection(
            title: l10n.verifyAskClassmates,
            children: [
              Padding(
                padding: const EdgeInsets.all(CsSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.verifyAskClassmatesHint,
                      style: context.text.bodyMedium?.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                    const SizedBox(height: CsSpace.md),
                    Wrap(
                      spacing: CsSpace.sm,
                      runSpacing: CsSpace.sm,
                      children: [
                        CsPill(
                          icon: CsIcons.verifiedOutline,
                          label: l10n.verifyProgress(mine.vouches, mine.needed),
                          highlight: true,
                        ),
                        for (final p in mine.vouchedBy)
                          CsPill(icon: CsIcons.profile, label: p.name),
                      ],
                    ),
                    const SizedBox(height: CsSpace.md),
                    FilledButton.icon(
                      onPressed: mine.link.isEmpty
                          ? null
                          : () => _share(context),
                      icon: const Icon(CsIcons.share),
                      label: Text(l10n.verifyShareLink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
