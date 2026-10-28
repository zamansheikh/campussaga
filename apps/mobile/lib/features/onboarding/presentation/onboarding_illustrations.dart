import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

// Onboarding pictures drawn from real UI pieces in the brand palette, so
// they follow light / dark mode and the student's language. Each one is
// laid out on a 340 x 330 canvas that the slide scales to fit.

/// Slide 1: the next-class card with a reminder and a room change.
class ClassIllustration extends StatelessWidget {
  const ClassIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _Backdrop(),
        // The next class after it, a little faded.
        Positioned(
          left: 40,
          right: 40,
          top: 226,
          child: _Card(
            child: Row(
              children: [
                _TimeBlock(time: '12:00', color: cs.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CSE 313', style: context.text.labelLarge),
                      Text(
                        'Operating Systems',
                        style: context.text.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 26,
          right: 26,
          top: 52,
          child: _Card(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CsBadge(
                        label: l10n.illusNextClass,
                        icon: CsIcons.time,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.illusStartsIn,
                      style: context.text.labelLarge?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('CSE 311', style: context.text.titleLarge),
                Text(
                  'Database Systems',
                  style: context.text.bodyMedium?.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Meta(icon: CsIcons.room, text: '504'),
                    const SizedBox(width: 16),
                    _Meta(icon: CsIcons.time, text: '10:00'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 10,
          child: _Chip(icon: CsIcons.reminders, label: l10n.illusReminder),
        ),
        Positioned(
          right: 4,
          bottom: 0,
          child: _Chip(
            icon: CsIcons.swap,
            label: l10n.illusRoomChanged,
            accent: true,
          ),
        ),
      ],
    );
  }
}

/// Slide 2: a campus issue with "me too" support and its status.
class VoiceIllustration extends StatelessWidget {
  const VoiceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _Backdrop(),
        Positioned(
          left: 26,
          right: 26,
          top: 72,
          child: _Card(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CsIcons.hidden,
                        size: 16,
                        color: cs.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.illusAnonymous,
                        style: context.text.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.illusIssueTitle,
                  style: context.text.titleMedium,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CsBadge(
                        label: l10n.illusInProgress,
                        icon: CsIcons.construction,
                        tone: CsBadgeTone.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(CsRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CsIcons.meTooFill,
                            size: 15,
                            color: cs.onPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${l10n.illusMeToo} · 128',
                            style: context.text.labelMedium?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Positioned(right: 18, top: 26, child: _Faces()),
        Positioned(
          left: 10,
          bottom: 48,
          child: _Chip(
            icon: CsIcons.trending,
            label: '+24 ${l10n.illusMeToo}',
            accent: true,
          ),
        ),
      ],
    );
  }
}

/// Slide 3: a shield with what keeps students safe around it.
class PrivacyIllustration extends StatelessWidget {
  const PrivacyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = context.cs;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const _Backdrop(),
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withValues(alpha: 0.12),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(CsIcons.verified, size: 52, color: Colors.white),
          ),
        ),
        Positioned(
          left: 6,
          top: 24,
          child: _Chip(icon: CsIcons.verified, label: l10n.verifiedStudent),
        ),
        Positioned(
          right: 0,
          bottom: 62,
          child: _Chip(icon: CsIcons.hidden, label: l10n.illusAnonymous),
        ),
        Positioned(
          left: 6,
          bottom: 12,
          child: _Chip(
            icon: CsIcons.emailAt,
            label: 'you@university.edu.bd',
            accent: true,
          ),
        ),
      ],
    );
  }
}

/// Soft brand-coloured circle behind each picture.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                cs.primaryContainer,
                cs.primaryContainer.withValues(alpha: 0),
              ],
              stops: const [0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.elevated = false});

  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(CsRadius.lg),
        border: Border.all(color: cs.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Small floating pill with an icon, e.g. "Reminder set".
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.accent = false});

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final fg = accent ? cs.statusInProgress.fg : cs.primary;
    final tile = accent ? cs.statusInProgress.bg : cs.primaryContainer;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(CsRadius.full),
        border: Border.all(color: cs.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: tile, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 8),
          Text(label, style: context.text.labelLarge),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: context.text.bodyMedium?.copyWith(color: cs.textSecondary),
        ),
      ],
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.time, required this.color});

  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.cs.surfaceVariant,
        borderRadius: BorderRadius.circular(CsRadius.sm),
      ),
      child: Text(time, style: context.text.labelLarge?.copyWith(color: color)),
    );
  }
}

/// Overlapping initials: classmates who said "me too".
class _Faces extends StatelessWidget {
  const _Faces();

  @override
  Widget build(BuildContext context) {
    const names = ['Nabila Islam', 'Tanvir Ahmed', 'Sadia Rahman'];
    return SizedBox(
      width: 34.0 + 24 * (names.length - 1) + 6,
      height: 40,
      child: Stack(
        children: [
          for (var i = 0; i < names.length; i++)
            Positioned(
              left: 24.0 * i,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.cs.background,
                  shape: BoxShape.circle,
                ),
                child: CsAvatar(name: names[i], size: 34),
              ),
            ),
        ],
      ),
    );
  }
}
