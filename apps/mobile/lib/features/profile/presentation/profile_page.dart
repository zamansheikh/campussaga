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
import '../../auth/presentation/auth_error_text.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../reminders/presentation/bloc/reminders_cubit.dart';

/// Who you are, your preferences, and account actions.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
            CsSection(
              title: l10n.preferences,
              children: [
                CsRow(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.reminders,
                  value: reminders.active
                      ? l10n.remindersOnValue(reminders.settings.minutesBefore)
                      : l10n.remindersOff,
                  onTap: () => context.push(Routes.reminders),
                ),
                CsRow(
                  icon: Icons.palette_outlined,
                  title: l10n.theme,
                  value: themeLabel,
                  onTap: () => _pickTheme(context, settings.themeMode),
                ),
                CsRow(
                  icon: Icons.translate_rounded,
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
                CsRow(
                  icon: Icons.edit_outlined,
                  title: l10n.editProfile,
                  onTap: () => context.push(Routes.editProfile),
                ),
                CsRow(
                  icon: Icons.logout_rounded,
                  title: l10n.signOut,
                  onTap: () => context.read<AuthBloc>().add(
                    const AuthSignOutRequested(),
                  ),
                ),
                const _DeleteAccountRow(),
              ],
            ),
            const SizedBox(height: CsSpace.lg),
            CsSection(
              title: l10n.about,
              children: [
                CsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  trailing: Icon(
                    Icons.open_in_new_rounded,
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
          icon: Icons.brightness_auto_outlined,
        ),
        CsOption(
          ThemeMode.light,
          l10n.themeLight,
          icon: Icons.light_mode_outlined,
        ),
        CsOption(
          ThemeMode.dark,
          l10n.themeDark,
          icon: Icons.dark_mode_outlined,
        ),
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
        CsOption(
          'system',
          l10n.languageSystem,
          icon: Icons.phone_android_rounded,
        ),
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
                CsAvatar(name: name, size: 60),
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
                      CsBadge(
                        label: l10n.verifiedStudent,
                        icon: Icons.verified_rounded,
                        tone: CsBadgeTone.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CsSpace.md),
            const Divider(),
            const SizedBox(height: CsSpace.md),
            _InfoLine(
              icon: Icons.account_balance_outlined,
              text: user.university.localName(lang),
            ),
            const SizedBox(height: CsSpace.sm),
            if (classLine.isNotEmpty)
              _InfoLine(icon: Icons.school_outlined, text: classLine)
            else
              InkWell(
                borderRadius: BorderRadius.circular(CsRadius.sm),
                onTap: () => context.push(Routes.editProfile),
                child: _InfoLine(
                  icon: Icons.add_circle_outline_rounded,
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded, color: context.cs.error),
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.cs.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (ok ?? false) auth.add(const AuthAccountDeleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deleting = context.select((AuthBloc b) => b.state.deleting);
    return CsRow(
      icon: Icons.delete_outline_rounded,
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
