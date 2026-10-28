import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_form_cubit.dart';
import '../widgets/profile_form.dart';
import '../widgets/university_picker.dart';
import '../widgets/user_avatar.dart';

/// Shown after sign-in while name, department or batch is missing, or (a
/// student who signed in with Gmail) the university. Saving (or "Later",
/// once a university is chosen) lets the router open the app.
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthBloc>();
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => ProfileFormCubit(getIt<ProfileRepository>()),
      child: Scaffold(
        body: SafeArea(
          child: CsPage(
            padding: const EdgeInsets.fromLTRB(
              CsSpace.lg,
              CsSpace.xl,
              CsSpace.lg,
              CsSpace.lg,
            ),
            children: [
              Row(
                children: [
                  UserAvatar.of(user, size: 56),
                  const Spacer(),
                  CsBadge(label: l10n.setupProfileStep, icon: CsIcons.flag),
                ],
              ),
              const SizedBox(height: CsSpace.lg),
              Text(l10n.setupProfileTitle, style: context.text.headlineSmall),
              const SizedBox(height: CsSpace.sm),
              Text(
                l10n.setupProfileSubtitle,
                style: context.text.bodyLarge?.copyWith(
                  color: context.cs.textSecondary,
                ),
              ),
              const SizedBox(height: CsSpace.md),
              if (user.verified && user.university != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CsBadge(
                    label: user.university!.localName(lang),
                    icon: CsIcons.verified,
                    tone: CsBadgeTone.success,
                  ),
                )
              else ...[
                Text(l10n.chooseUniversityHint, style: context.text.bodySmall),
                const SizedBox(height: CsSpace.sm),
                const UniversityField(),
              ],
              const SizedBox(height: CsSpace.lg),
              ProfileForm(
                initial: user,
                onSaved: (u) => auth.add(AuthProfileUpdated(u)),
                // The university can't wait: groups need it.
                secondary: user.university == null
                    ? null
                    : TextButton(
                        onPressed: () =>
                            auth.add(const AuthProfileSetupSkipped()),
                        child: Text(l10n.setupLater),
                      ),
              ),
              // A wrong Google account picked by mistake: start over.
              const SizedBox(height: CsSpace.lg),
              Text(
                l10n.signedInAs(user.email),
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
              TextButton(
                onPressed: () => auth.add(const AuthSignOutRequested()),
                child: Text(l10n.useAnotherAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
