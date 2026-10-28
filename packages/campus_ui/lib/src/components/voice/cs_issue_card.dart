import 'package:flutter/material.dart';

import '../../theme/cs_tokens.dart';
import '../../tokens/cs_icons.dart';
import '../../tokens/dimensions.dart';
import 'cs_category.dart';

/// An issue in a list: category, title, 2-line preview, status, counts,
/// time and how its author appears (mask = anonymous).
class CsIssueCard extends StatelessWidget {
  const CsIssueCard({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.status,
    required this.meTooCount,
    required this.commentCount,
    required this.timeLabel,
    required this.authorLabel,
    this.anonymous = true,
    this.preview = '',
    this.thumbnail,
    this.flags = const [],
    this.voted = false,
    this.onTap,
  });

  /// Wire name (icon and tint come from [CsCategoryStyle]).
  final String category;
  final String categoryLabel;
  final String title;
  final String preview;

  /// A [CsStatusChip].
  final Widget status;
  final String meTooCount;
  final String commentCount;
  final String timeLabel;

  /// "Anonymous", or the name on a named post.
  final String authorLabel;
  final bool anonymous;
  final Widget? thumbnail;

  /// Badges such as "Private" or "Under review".
  final List<Widget> flags;
  final bool voted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final muted = context.text.bodySmall?.copyWith(color: cs.textSecondary);
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CsRadius.lg),
        side: BorderSide(color: cs.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CsCategoryIcon(category: category, size: 28),
                  const SizedBox(width: CsSpace.sm),
                  Expanded(
                    child: Text(
                      categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(
                        color: cs.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: CsSpace.sm),
                  Flexible(child: status),
                ],
              ),
              const SizedBox(height: CsSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(
                              color: cs.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (thumbnail != null) ...[
                    const SizedBox(width: CsSpace.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(CsRadius.sm),
                      child: SizedBox(width: 64, height: 64, child: thumbnail),
                    ),
                  ],
                ],
              ),
              if (flags.isNotEmpty) ...[
                const SizedBox(height: CsSpace.sm),
                Wrap(spacing: 6, runSpacing: 6, children: flags),
              ],
              const SizedBox(height: CsSpace.sm),
              Row(
                children: [
                  Icon(
                    voted ? CsIcons.meTooFill : CsIcons.meToo,
                    size: 16,
                    color: voted ? cs.primary : cs.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(meTooCount, style: muted),
                  const SizedBox(width: CsSpace.md),
                  Icon(CsIcons.comment, size: 16, color: cs.textSecondary),
                  const SizedBox(width: 4),
                  Text(commentCount, style: muted),
                  const SizedBox(width: CsSpace.md),
                  Icon(
                    anonymous ? CsIcons.anonymous : CsIcons.profile,
                    size: 16,
                    color: cs.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      authorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  const SizedBox(width: CsSpace.sm),
                  Text(timeLabel, style: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
