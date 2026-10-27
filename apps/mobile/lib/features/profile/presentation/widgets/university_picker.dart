import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../../../auth/presentation/auth_error_text.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// The student's university, for a not-verified student (signed in with
/// Gmail): tap to choose or change it. Saved at once.
class UniversityField extends StatefulWidget {
  const UniversityField({super.key});

  @override
  State<UniversityField> createState() => _UniversityFieldState();
}

class _UniversityFieldState extends State<UniversityField> {
  bool _busy = false;
  Failure? _failure;

  Future<void> _pick() async {
    final auth = context.read<AuthBloc>();
    final picked = await showUniversityPicker(context);
    if (picked == null || !mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final user = await getIt<ProfileRepository>().setUniversity(picked.id);
      auth.add(AuthProfileUpdated(user));
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    final lang = Localizations.localeOf(context).languageCode;
    final uni = context.select((AuthBloc b) => b.state.user?.university);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: uni == null ? cs.primaryContainer : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CsRadius.md),
            side: BorderSide(color: uni == null ? cs.primary : cs.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy ? null : _pick,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.account_balance_outlined, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.universityLabel,
                          style: context.text.labelMedium,
                        ),
                        Text(
                          uni?.localName(lang) ?? l10n.chooseUniversity,
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_busy)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      uni == null ? '' : l10n.changeAction,
                      style: context.text.labelLarge?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  if (!_busy && uni == null)
                    Icon(Icons.chevron_right_rounded, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
        if (_failure != null)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.xs),
            child: Text(
              authErrorText(l10n, _failure!),
              style: context.text.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }
}

/// A full-height sheet: search and pick a university.
Future<University?> showUniversityPicker(BuildContext context) =>
    showModalBottomSheet<University>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _UniversityPicker(),
    );

class _UniversityPicker extends StatefulWidget {
  const _UniversityPicker();

  @override
  State<_UniversityPicker> createState() => _UniversityPickerState();
}

class _UniversityPickerState extends State<_UniversityPicker> {
  late final Future<List<University>> _all = getIt<ProfileRepository>()
      .universities();
  String _q = '';

  bool _matches(University u) {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return true;
    return u.name.toLowerCase().contains(q) ||
        (u.nameBn?.contains(_q.trim()) ?? false) ||
        u.slug.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.md,
                0,
                CsSpace.md,
                CsSpace.sm,
              ),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: l10n.searchUniversity,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<University>>(
                future: _all,
                builder: (context, snap) {
                  if (snap.hasError) {
                    final e = snap.error;
                    return Center(
                      child: Text(
                        e is Failure
                            ? authErrorText(l10n, e)
                            : l10n.errorGeneric,
                      ),
                    );
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final shown = list.where(_matches).toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
                  return ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final u = shown[i];
                      final local = u.localName(lang);
                      return ListTile(
                        title: Text(local),
                        subtitle: local == u.name ? null : Text(u.name),
                        onTap: () => Navigator.of(context).pop(u),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
