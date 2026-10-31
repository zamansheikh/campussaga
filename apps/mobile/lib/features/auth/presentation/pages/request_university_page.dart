import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../profile/presentation/widgets/university_picker.dart';
import '../../../verification/presentation/verification_text.dart';
import '../widgets/notice_banner.dart';

/// "My university email isn't recognized": the student names their
/// university (or picks it from the list) and we add its email domain.
class RequestUniversityPage extends StatefulWidget {
  const RequestUniversityPage({super.key, this.email = ''});

  /// The email that wasn't recognized.
  final String email;

  @override
  State<RequestUniversityPage> createState() => _RequestUniversityPageState();
}

class _RequestUniversityPageState extends State<RequestUniversityPage> {
  final _name = TextEditingController();
  University? _picked;
  bool _busy = false;
  bool _sent = false;
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final u = await showUniversityPicker(context, currentId: _picked?.id);
    if (u != null && mounted) {
      setState(() {
        _picked = u;
        _name.clear();
        _problem = null;
      });
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    if (_picked == null && _name.text.trim().isEmpty) {
      setState(() => _problem = l10n.requestUniversityNeeded);
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await getIt<VerificationRepository>().requestUniversity(
        email: widget.email,
        universityId: _picked?.id,
        universityName: _picked == null ? _name.text : null,
      );
      if (mounted) setState(() => _sent = true);
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _problem = verificationErrorText(l10n, f));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestUniversityTitle)),
      body: SafeArea(
        child: _sent
            ? CsEmptyState(
                icon: CsIcons.checkCircle,
                title: l10n.requestUniversityDone,
                message: l10n.requestUniversityDoneBody,
                actionLabel: l10n.gotIt,
                onAction: () => context.pop(),
              )
            : CsPage(
                children: [
                  Text(
                    l10n.requestUniversityHint,
                    style: context.text.bodyLarge?.copyWith(
                      color: context.cs.textSecondary,
                    ),
                  ),
                  if (widget.email.isNotEmpty) ...[
                    const SizedBox(height: CsSpace.sm),
                    Text(
                      l10n.requestUniversityEmail(widget.email),
                      style: context.text.bodySmall,
                    ),
                  ],
                  const SizedBox(height: CsSpace.lg),
                  TextField(
                    controller: _name,
                    enabled: !_busy && _picked == null,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      labelText: l10n.requestUniversityName,
                      prefixIcon: const Icon(CsIcons.university),
                    ),
                  ),
                  const SizedBox(height: CsSpace.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CsPill(
                      icon: CsIcons.search,
                      label:
                          _picked?.localName(lang) ??
                          l10n.requestUniversityPick,
                      onTap: _busy ? null : _pick,
                      trailing: CsIcons.chevronRight,
                    ),
                  ),
                  if (_problem != null) ...[
                    const SizedBox(height: CsSpace.md),
                    NoticeBanner(text: _problem!),
                  ],
                  const SizedBox(height: CsSpace.lg),
                  FilledButton(
                    onPressed: _busy ? null : _send,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.requestUniversitySend),
                  ),
                ],
              ),
      ),
    );
  }
}
