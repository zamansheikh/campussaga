import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../growth_text.dart';

/// "Show me on leaderboards": off hides my name (campaign leaderboards
/// show "A student at …" instead).
class LeaderboardSwitchRow extends StatefulWidget {
  const LeaderboardSwitchRow({super.key});

  @override
  State<LeaderboardSwitchRow> createState() => _LeaderboardSwitchRowState();
}

class _LeaderboardSwitchRowState extends State<LeaderboardSwitchRow> {
  bool _busy = false;

  Future<void> _set(bool shown) async {
    final auth = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final user = await getIt<ProfileRepository>().setLeaderboardHidden(
        hidden: !shown,
      );
      auth.add(AuthProfileUpdated(user));
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(growthErrorText(l10n, f))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hidden =
        context.select((AuthBloc b) => b.state.user?.leaderboardHidden) ??
        false;
    return CsRow(
      icon: hidden ? CsIcons.hidden : CsIcons.visible,
      title: l10n.leaderboardShowTitle,
      subtitle: l10n.leaderboardShowHint,
      onTap: _busy ? null : () => _set(hidden),
      trailing: Switch(value: !hidden, onChanged: _busy ? null : _set),
    );
  }
}
