import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/settings/bloc/settings_cubit.dart';
import 'onboarding_illustrations.dart';

/// Three welcome slides, shown once before the first sign-in.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;

  static const _count = 3;
  bool get _last => _index == _count - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => context.read<SettingsCubit>().completeOnboarding();

  void _go(int page) => _pages.animateToPage(
    page,
    duration: CsMotion.normal * 1.6,
    curve: CsMotion.curve,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      _Slide(
        illustration: const ClassIllustration(),
        title: l10n.onboarding1Title,
        body: l10n.onboarding1Body,
      ),
      _Slide(
        illustration: const VoiceIllustration(),
        badge: l10n.comingSoon,
        title: l10n.onboarding2Title,
        body: l10n.onboarding2Body,
      ),
      _Slide(
        illustration: const PrivacyIllustration(),
        title: l10n.onboarding3Title,
        body: l10n.onboarding3Body,
      ),
    ];

    // Android back goes to the previous slide first.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_index - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CsSize.contentMaxWidth,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CsSpace.lg,
                      CsSpace.sm,
                      CsSpace.sm,
                      0,
                    ),
                    child: Row(
                      children: [
                        const CsBrandMark(size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.appName,
                            style: context.text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _last ? 0 : 1,
                          duration: CsMotion.fast,
                          child: TextButton(
                            onPressed: _last ? null : _finish,
                            child: Text(l10n.onboardingSkip),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _index = i),
                      children: slides,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CsSpace.lg,
                      CsSpace.md,
                      CsSpace.lg,
                      CsSpace.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: CsDots(count: _count, index: _index),
                        ),
                        const SizedBox(height: CsSpace.lg),
                        FilledButton(
                          onPressed: _last ? _finish : () => _go(_index + 1),
                          child: AnimatedSwitcher(
                            duration: CsMotion.fast,
                            child: Text(
                              _last
                                  ? l10n.onboardingStart
                                  : l10n.onboardingNext,
                              key: ValueKey(_last),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.illustration,
    required this.title,
    required this.body,
    this.badge,
  });

  final Widget illustration;
  final String title;
  final String body;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.lg),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                child: SizedBox(width: 340, height: 330, child: illustration),
              ),
            ),
          ),
          if (badge != null) ...[
            CsBadge(
              label: badge!,
              icon: Icons.auto_awesome_rounded,
              tone: CsBadgeTone.accent,
            ),
            const SizedBox(height: CsSpace.md),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: CsSpace.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.cs.textSecondary,
            ),
          ),
          const SizedBox(height: CsSpace.sm),
        ],
      ),
    );
  }
}
