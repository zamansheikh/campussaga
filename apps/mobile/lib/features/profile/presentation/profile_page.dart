import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di.dart';
import '../../../app/env.dart';
import '../../../app/router.dart';
import '../../../app/settings/bloc/settings_cubit.dart';
import '../../../app/version/app_version.dart';
import '../../../app/version/version_gate_cubit.dart';
import '../../auth/presentation/auth_error_text.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../growth/presentation/widgets/badges_section.dart';
import '../../growth/presentation/widgets/campaigns_section.dart';
import '../../growth/presentation/widgets/invite_card.dart';
import '../../growth/presentation/widgets/leaderboard_switch.dart';
import '../../reminders/presentation/bloc/reminders_cubit.dart';
import '../../verification/presentation/widgets/verify_banner.dart';
import 'widgets/university_picker.dart';
import 'widgets/user_avatar.dart';

/// Who you are, your preferences, and account actions.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.show});

  /// A section to scroll to when opened (from a push): `invites` or
  /// `badges`.
  final String? show;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final reminders = context.watch<RemindersCubit>().state;

    final themeLabel = switch (settings.themeMode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
    final languageLabel = switch (settings.locale?.languageCode) {
      'en' => 'English',
      'bn' => 'বাংলা',
      _ => l10n.languageSystem,
    };

    return BlocListener<AuthBloc, AuthState>(
      // Deleting failed (e.g. offline): still signed in, say why.
      listenWhen: (a, b) =>
          a.deleting && !b.deleting && b.status == AuthStatus.signedIn,
      listener: (context, s) {
        if (s.failure == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorText(l10n, s.failure!))),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.navProfile)),
        body: CsPage(
          children: [
            const _ProfileHeader(),
            const SizedBox(height: CsSpace.lg),
            const VerifyBanner(),
            if (context.select((AuthBloc b) => b.state.user?.campusAdmin) ??
                false) ...[
              CsSection(
                children: [
                  CsRow(
                    icon: CsIcons.safety,
                    title: l10n.campusAdminEntry(
                      context
                              .read<AuthBloc>()
                              .state
                              .user
                              ?.university
                              ?.localName(
                                Localizations.localeOf(context).languageCode,
                              ) ??
                          '',
                    ),
                    onTap: () => context.push(Routes.campusAdmin),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.lg),
            ],
            if (context.select(
              (VersionGateCubit g) => g.state.feature('campusVoice'),
            )) ...[
              CsSection(
                children: [
                  CsRow(
                    icon: CsIcons.myIssues,
                    title: l10n.voiceMyIssues,
                    onTap: () => context.push(Routes.campusMine),
                  ),
                ],
              ),
              const SizedBox(height: CsSpace.lg),
            ],
            InviteCard(reveal: show == 'invites'),
            const CampaignsSection(),
            BadgesSection(reveal: show == 'badges'),
            CsSection(
              title: l10n.preferences,
              children: [
                CsRow(
                  icon: CsIcons.bell,
                  title: l10n.reminders,
                  value: reminders.active
                      ? l10n.remindersOnValue(reminders.settings.minutesBefore)
                      : l10n.remindersOff,
                  onTap: () => context.push(Routes.reminders),
                ),
                CsRow(
                  icon: CsIcons.theme,
                  title: l10n.theme,
                  value: themeLabel,
                  onTap: () => _pickTheme(context, settings.themeMode),
                ),
                CsRow(
                  icon: CsIcons.language,
                  title: l10n.language,
                  value: languageLabel,
                  onTap: () => _pickLanguage(context, settings.locale),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.account,
              children: [
                if (!(context.select((AuthBloc b) => b.state.user?.verified) ??
                    true))
                  CsRow(
                    icon: CsIcons.verifiedOutline,
                    title: l10n.verifyWithUniEmail,
                    subtitle: l10n.verifyHint,
                    onTap: () => context.push(Routes.verifyEmail),
                  ),
                CsRow(
                  icon: CsIcons.edit,
                  title: l10n.editProfile,
                  onTap: () => context.push(Routes.editProfile),
                ),
                const LeaderboardSwitchRow(),
                CsRow(
                  icon: CsIcons.signOut,
                  title: l10n.signOut,
                  onTap: () => context.read<AuthBloc>().add(
                    const AuthSignOutRequested(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.about,
              children: [
                CsRow(
                  icon: CsIcons.info,
                  title: l10n.helpFeedback,
                  subtitle: l10n.helpFeedbackHint,
                  onTap: () => context.push(Routes.help),
                ),
                CsRow(
                  icon: CsIcons.privacy,
                  title: l10n.privacyPolicy,
                  trailing: Icon(
                    CsIcons.openExternal,
                    size: 18,
                    color: context.cs.textSecondary,
                  ),
                  onTap: () => launchUrl(
                    Uri.parse(Env.privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
            // Kept apart from Sign out, at the very end, so nobody taps it by
            // mistake; the dialog asks for a tick before it deletes.
            const SizedBox(height: CsSpace.xxl),
            const CsSection(children: [_DeleteAccountRow()]),
            const SizedBox(height: CsSpace.xl),
            const _Footer(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context, ThemeMode current) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final picked = await CsOptionSheet.show<ThemeMode>(
      context: context,
      title: l10n.theme,
      selected: current,
      options: [
        CsOption(
          ThemeMode.system,
          l10n.themeSystem,
          subtitle: l10n.themeSystemHint,
          icon: CsIcons.themeSystem,
        ),
        CsOption(ThemeMode.light, l10n.themeLight, icon: CsIcons.light),
        CsOption(ThemeMode.dark, l10n.themeDark, icon: CsIcons.dark),
      ],
    );
    if (picked != null) cubit.setThemeMode(picked);
  }

  Future<void> _pickLanguage(BuildContext context, Locale? current) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final picked = await CsOptionSheet.show<String>(
      context: context,
      title: l10n.language,
      selected: current?.languageCode ?? 'system',
      options: [
        CsOption('system', l10n.languageSystem, icon: CsIcons.phone),
        const CsOption('en', 'English', subtitle: 'English'),
        const CsOption('bn', 'বাংলা', subtitle: 'Bangla'),
      ],
    );
    if (picked != null) {
      cubit.setLocale(picked == 'system' ? null : Locale(picked));
    }
  }
}

/// Avatar, name, email, verified badge, university and class.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : user.email.split('@').first;
    final classLine = [
      user.department,
      user.batch,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CsSpace.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  userId: user.id,
                  name: name,
                  photoVersion: user.photoVersion,
                  googlePhotoUrl: user.googlePhotoUrl,
                  size: 60,
                ),
                const SizedBox(width: CsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: context.text.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: context.text.bodyMedium?.copyWith(
                          color: cs.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: CsSpace.sm),
                      if (user.verified)
                        CsBadge(
                          label: l10n.verifiedStudent,
                          icon: CsIcons.verified,
                          tone: CsBadgeTone.success,
                        )
                      else
                        CsBadge(
                          label: l10n.notVerified,
                          icon: CsIcons.help,
                          tone: CsBadgeTone.accent,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            const Divider(),
            const SizedBox(height: CsSpace.md),
            if (user.verified)
              InkWell(
                borderRadius: BorderRadius.circular(CsRadius.sm),
                onTap: () => _changeUniversity(context),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoLine(
                        icon: CsIcons.university,
                        text: user.university?.localName(lang) ?? '',
                      ),
                    ),
                    Text(
                      l10n.changeAction,
                      style: context.text.labelLarge?.copyWith(
                        color: context.cs.primary,
                      ),
                    ),
                  ],
                ),
              )
            else
              const UniversityField(),
            const SizedBox(height: CsSpace.sm),
            if (classLine.isNotEmpty)
              _InfoLine(icon: CsIcons.academic, text: classLine)
            else
              InkWell(
                borderRadius: BorderRadius.circular(CsRadius.sm),
                onTap: () => context.push(Routes.editProfile),
                child: _InfoLine(
                  icon: CsIcons.addCircle,
                  text: l10n.completeProfile,
                  highlight: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A verified student moves university (e.g. a master's elsewhere): with
/// the new university's email (stays verified), or picked from the list
/// (becomes not verified).
Future<void> _changeUniversity(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final how = await CsOptionSheet.show<String>(
    context: context,
    title: l10n.changeUniversity,
    selected: '',
    options: [
      CsOption(
        'email',
        l10n.changeWithEmail,
        subtitle: l10n.changeWithEmailHint,
        icon: CsIcons.verifiedOutline,
      ),
      CsOption(
        'pick',
        l10n.changeWithoutEmail,
        subtitle: l10n.changeWithoutEmailHint,
        icon: CsIcons.university,
      ),
    ],
  );
  if (how == null || !context.mounted) return;
  if (how == 'email') {
    await context.push(Routes.verifyEmail);
    return;
  }
  final uni = await showUniversityPicker(
    context,
    currentId: context.read<AuthBloc>().state.user?.university?.id,
  );
  if (uni == null || !context.mounted) return;
  final lang = Localizations.localeOf(context).languageCode;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.leaveVerifiedTitle(uni.localName(lang))),
      content: Text(l10n.leaveVerifiedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(l10n.moveAction),
        ),
      ],
    ),
  );
  if (!(ok ?? false) || !context.mounted) return;
  final auth = context.read<AuthBloc>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final user = await getIt<ProfileRepository>().setUniversity(
      uni.id,
      leaveVerified: true,
    );
    auth.add(AuthProfileUpdated(user));
    messenger.showSnackBar(SnackBar(content: Text(l10n.universityChanged)));
  } on Failure catch (f) {
    messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, f))));
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = highlight ? cs.primary : cs.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: context.text.bodyMedium?.copyWith(
              color: highlight ? cs.primary : cs.textPrimary,
              fontWeight: highlight ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow();

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthBloc>();
    var sure = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: Icon(CsIcons.delete, color: context.cs.error),
          title: Text(l10n.deleteAccountTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountBody),
              const SizedBox(height: CsSpace.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: sure,
                onChanged: (v) => setState(() => sure = v ?? false),
                title: Text(l10n.deleteAccountUnderstand),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              // Dialog-sized, like the Cancel next to it.
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
                backgroundColor: context.cs.error,
                foregroundColor: context.cs.onError,
                disabledBackgroundColor: context.cs.surfaceVariant,
                disabledForegroundColor: context.cs.textSecondary,
              ),
              onPressed: sure ? () => Navigator.of(context).pop(true) : null,
              child: Text(l10n.deleteAccountConfirm),
            ),
          ],
        ),
      ),
    );
    if (ok ?? false) auth.add(const AuthAccountDeleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deleting = context.select((AuthBloc b) => b.state.deleting);
    return CsRow(
      icon: CsIcons.delete,
      title: l10n.deleteAccount,
      subtitle: l10n.deleteAccountHint,
      destructive: true,
      showChevron: false,
      trailing: deleting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: deleting ? null : () => _confirm(context),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final version = getIt.isRegistered<AppVersion>()
        ? getIt<AppVersion>().version
        : null;
    return Column(
      children: [
        const CsBrandMark(size: 36),
        const SizedBox(height: CsSpace.sm),
        Text(l10n.appName, style: context.text.labelLarge),
        if (version != null)
          Text(l10n.versionLabel(version), style: context.text.bodySmall),
        const SizedBox(height: CsSpace.xs),
        Text(l10n.madeFor, style: context.text.bodySmall),
      ],
    );
  }
}
