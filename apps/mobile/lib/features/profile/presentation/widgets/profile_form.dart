import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/auth_error_text.dart';
import '../bloc/profile_form_cubit.dart';

/// Name, department (with suggestions from classmates) and batch.
/// Used by the first-time setup screen and the edit screen.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.initial,
    required this.onSaved,
    this.secondary,
  });

  final UserProfile initial;
  final ValueChanged<UserProfile> onSaved;

  /// Optional extra button under Save (e.g. "Later").
  final Widget? secondary;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final _name = TextEditingController(text: widget.initial.displayName);
  late final _department = TextEditingController(
    text: widget.initial.department,
  );
  late final _batch = TextEditingController(text: widget.initial.batch);
  final _departmentFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _batch.dispose();
    _departmentFocus.dispose();
    super.dispose();
  }

  void _submit() => context.read<ProfileFormCubit>().submit(
    displayName: _name.text,
    department: _department.text,
    batch: _batch.text,
  );

  String? _error(AppLocalizations l10n, ProfileFormState s, String field) {
    return switch (s.fieldErrors[field]) {
      ProfileFieldError.required => l10n.errorFieldRequired,
      ProfileFieldError.tooLong => l10n.errorFieldTooLong,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ProfileFormCubit>();
    return BlocConsumer<ProfileFormCubit, ProfileFormState>(
      listenWhen: (a, b) => b.status == ProfileFormStatus.saved,
      listener: (context, s) => widget.onSaved(s.saved!),
      builder: (context, s) {
        final busy = s.saving || s.status == ProfileFormStatus.saved;
        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                enabled: !busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: l10n.displayNameLabel,
                  errorText: _error(l10n, s, 'displayName'),
                ),
              ),
              const SizedBox(height: CsSpace.md),
              RawAutocomplete<String>(
                textEditingController: _department,
                focusNode: _departmentFocus,
                optionsBuilder: (v) => cubit.suggestDepartments(v.text),
                fieldViewBuilder: (context, controller, focus, onSubmit) =>
                    TextField(
                      controller: controller,
                      focusNode: focus,
                      enabled: !busy,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.departmentLabel,
                        hintText: l10n.departmentHint,
                        errorText: _error(l10n, s, 'department'),
                      ),
                    ),
                optionsViewBuilder: (context, onSelected, options) =>
                    _Suggestions(options: options, onSelected: onSelected),
              ),
              const SizedBox(height: CsSpace.md),
              TextField(
                controller: _batch,
                enabled: !busy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.batchLabel,
                  hintText: l10n.batchHint,
                  errorText: _error(l10n, s, 'batch'),
                ),
              ),
              if (s.failure != null) ...[
                const SizedBox(height: CsSpace.md),
                Text(
                  authErrorText(l10n, s.failure!),
                  style: context.text.bodyMedium?.copyWith(
                    color: context.cs.error,
                  ),
                ),
              ],
              const SizedBox(height: CsSpace.lg),
              FilledButton(
                onPressed: busy ? null : _submit,
                child: s.saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveProfile),
              ),
              if (widget.secondary != null) ...[
                const SizedBox(height: CsSpace.sm),
                widget.secondary!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.options, required this.onSelected});

  final Iterable<String> options;
  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(CsRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final o in options)
                ListTile(title: Text(o), onTap: () => onSelected(o)),
            ],
          ),
        ),
      ),
    );
  }
}
