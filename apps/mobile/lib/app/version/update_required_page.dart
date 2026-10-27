import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown instead of the app when this build is no longer supported.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key, this.storeUrl});

  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CsSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    size: 56,
                    color: context.cs.primary,
                  ),
                  const SizedBox(height: CsSpace.md),
                  Text(
                    l10n.updateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: CsSpace.sm),
                  Text(
                    l10n.updateRequiredBody,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.cs.textSecondary,
                    ),
                  ),
                  const SizedBox(height: CsSpace.lg),
                  if (storeUrl != null)
                    FilledButton(
                      onPressed: () => launchUrl(
                        Uri.parse(storeUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(l10n.updateNow),
                    )
                  else
                    Text(
                      l10n.updateFromStore,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
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
