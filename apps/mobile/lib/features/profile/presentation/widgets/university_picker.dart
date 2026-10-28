import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di.dart';
import '../../../../app/env.dart';
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
    final picked = await showUniversityPicker(
      context,
      currentId: auth.state.user?.university?.id,
    );
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
                  if (uni == null)
                    Icon(CsIcons.university, color: cs.primary)
                  else
                    UniversityBadge(university: uni, size: 40),
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
                        if (uni != null && universityMeta(uni).isNotEmpty)
                          Text(
                            universityMeta(uni),
                            style: context.text.bodySmall?.copyWith(
                              color: cs.textSecondary,
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
                    Icon(CsIcons.chevronRight, color: cs.primary),
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

/// A tall sheet: search and pick a university. [currentId] is marked and
/// shown first.
Future<University?> showUniversityPicker(
  BuildContext context, {
  String? currentId,
}) {
  // Close the keyboard of the form behind: the list needs the room.
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<University>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _UniversityPicker(currentId: currentId),
  );
}

class _UniversityPicker extends StatefulWidget {
  const _UniversityPicker({this.currentId});

  final String? currentId;

  @override
  State<_UniversityPicker> createState() => _UniversityPickerState();
}

class _UniversityPickerState extends State<_UniversityPicker> {
  late final Future<List<University>> _all = getIt<ProfileRepository>()
      .universities();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Section titles (String) and universities, in display order.
  List<Object> _entries(List<University> all, AppLocalizations l10n) {
    final q = _search.text.trim();
    if (q.isNotEmpty) {
      final scored =
          [
            for (final u in all)
              if (u.searchScore(q) case final s when s > 0) (u, s),
          ]..sort((a, b) {
            final byScore = b.$2.compareTo(a.$2);
            return byScore != 0 ? byScore : a.$1.name.compareTo(b.$1.name);
          });
      if (scored.isEmpty) return const [];
      return [
        l10n.universityMatches(scored.length),
        for (final e in scored) e.$1,
      ];
    }
    final sorted = [...all]..sort((a, b) => a.name.compareTo(b.name));
    final current = sorted.where((u) => u.id == widget.currentId).firstOrNull;
    return [
      if (current != null) ...[l10n.currentUniversity, current],
      l10n.allUniversities,
      ...sorted,
    ];
  }

  Future<void> _askToAdd(AppLocalizations l10n) => launchUrl(
    Uri(
      scheme: 'mailto',
      path: Env.supportEmail,
      query:
          'subject=${Uri.encodeComponent(l10n.addUniversitySubject)}'
          '&body=${Uri.encodeComponent('${_search.text.trim()}\n')}',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.9,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(CsSpace.lg, 0, CsSpace.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.chooseUniversity,
                      style: context.text.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CsIcons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CsSpace.lg,
                0,
                CsSpace.lg,
                CsSpace.md,
              ),
              child: Text(
                l10n.universityPickerHint,
                style: context.text.bodyMedium?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
              child: ValueListenableBuilder(
                valueListenable: _search,
                builder: (context, value, _) => TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.searchUniversity,
                    prefixIcon: const Icon(CsIcons.search),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.cancel,
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(CsIcons.clear),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CsSpace.sm),
            Expanded(
              child: FutureBuilder<List<University>>(
                future: _all,
                builder: (context, snap) {
                  if (snap.hasError) {
                    final e = snap.error;
                    return CsEmptyState(
                      icon: CsIcons.offline,
                      title: e is Failure
                          ? authErrorText(l10n, e)
                          : l10n.errorGeneric,
                    );
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = _entries(list, l10n);
                  if (entries.isEmpty) {
                    return SingleChildScrollView(
                      child: CsEmptyState(
                        icon: CsIcons.searchEmpty,
                        title: l10n.noUniversityFound,
                        message: l10n.noUniversityFoundHint,
                        actionLabel: l10n.askToAddUniversity,
                        onAction: () => _askToAdd(l10n),
                      ),
                    );
                  }
                  return ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      CsSpace.sm,
                      0,
                      CsSpace.sm,
                      CsSpace.lg,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => switch (entries[i]) {
                      final String title => _SectionTitle(title),
                      final University u => _UniversityRow(
                        university: u,
                        selected: u.id == widget.currentId,
                        onTap: () => Navigator.of(context).pop(u),
                      ),
                      _ => const SizedBox.shrink(),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      CsSpace.md,
      CsSpace.md,
      CsSpace.md,
      CsSpace.xs,
    ),
    child: Text(
      text.toUpperCase(),
      style: context.text.labelMedium?.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: context.cs.textSecondary,
      ),
    ),
  );
}

class _UniversityRow extends StatelessWidget {
  const _UniversityRow({
    required this.university,
    required this.selected,
    required this.onTap,
  });

  final University university;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final lang = Localizations.localeOf(context).languageCode;
    final u = university;
    final local = u.localName(lang);
    final meta = universityMeta(u);
    return Material(
      color: selected ? cs.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(CsRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CsSpace.sm,
            vertical: 10,
          ),
          child: Row(
            children: [
              UniversityBadge(university: u, strong: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    if (local != u.name)
                      Text(
                        u.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: cs.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: CsSpace.sm),
                Icon(CsIcons.checkCircle, color: cs.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Dhaka · diu.edu.bd": where it is and its student email.
String universityMeta(University u) =>
    [if ((u.city ?? '').isNotEmpty) u.city!, ?u.mainDomain].join(' · ');

/// A rounded square with the university's short name (DIU, BUET, ...).
class UniversityBadge extends StatelessWidget {
  const UniversityBadge({
    super.key,
    required this.university,
    this.size = 44,
    this.strong = false,
  });

  final University university;
  final double size;

  /// Filled with the primary color (the chosen university).
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: strong ? cs.primary : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(CsRadius.sm + 2),
        border: strong ? null : Border.all(color: cs.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          university.badge,
          maxLines: 1,
          style: context.text.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: strong ? cs.onPrimary : cs.textPrimary,
          ),
        ),
      ),
    );
  }
}
