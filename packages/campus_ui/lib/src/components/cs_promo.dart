import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';
import '../tokens/cs_icons.dart';
import '../tokens/dimensions.dart';
import 'voice/cs_post.dart';

/// Sponsored content, drawn with the app's own parts so it never looks like
/// a foreign ad: the same surfaces, radii and type, a quiet "Sponsored"
/// label, and an ⓘ that says why and lets the student hide it. Strings come
/// from the caller (this package has no translations).

/// A brand's logo in a rounded square, or its first letter when there is
/// none or it fails to load.
class CsBrandLogo extends StatelessWidget {
  const CsBrandLogo({
    super.key,
    required this.name,
    this.logo,
    this.size = 40,
    this.round = false,
  });

  final String name;
  final ImageProvider? logo;
  final double size;

  /// A circle (as an author's avatar) instead of a rounded square.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final radius = round
        ? BorderRadius.circular(size)
        : BorderRadius.circular(size * 0.24);
    final letter = Container(
      color: cs.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: cs.textSecondary,
        ),
      ),
    );
    final img = logo;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: cs.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: img == null
            ? letter
            : ColoredBox(
                color: Colors.white,
                child: Image(
                  image: img,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => letter,
                ),
              ),
      ),
    );
  }
}

/// "Sponsored · Brand" with an ⓘ that opens the Why / Hide sheet.
class CsSponsoredLabel extends StatelessWidget {
  const CsSponsoredLabel({
    super.key,
    required this.label,
    this.brand,
    this.onInfo,
    this.infoLabel,
  });

  /// "Sponsored".
  final String label;
  final String? brand;
  final VoidCallback? onInfo;

  /// For screen readers ("Why am I seeing this?").
  final String? infoLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final style = context.text.labelSmall?.copyWith(
      color: cs.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    return Row(
      children: [
        Flexible(
          child: Text(
            [label, if (brand != null && brand!.isNotEmpty) brand].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (onInfo != null)
          _InfoButton(onTap: onInfo!, label: infoLabel ?? label),
      ],
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        // A 40 dp target around a small icon.
        padding: const EdgeInsets.all(10),
        child: Icon(CsIcons.info, size: 16, color: context.cs.textSecondary),
      ),
    ),
  );
}

/// The image of a card or feed ad: 2:1 (or [aspect]), cover, a quiet
/// placeholder colour behind it.
class _PromoImage extends StatelessWidget {
  const _PromoImage({required this.image, this.aspect = 2});

  final ImageProvider image;
  final double aspect;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspect,
    child: ColoredBox(
      color: context.cs.surfaceVariant,
      child: Image(
        image: image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    ),
  );
}

/// The Today ad: a wide picture, "Sponsored · Brand" ⓘ, a title, one line,
/// and one small button. As compact as the campaign card above it.
class CsPromoCard extends StatelessWidget {
  const CsPromoCard({
    super.key,
    required this.sponsoredLabel,
    required this.brand,
    required this.title,
    this.body = '',
    this.cta = '',
    this.image,
    this.onTap,
    this.onInfo,
    this.infoLabel,
  });

  final String sponsoredLabel;
  final String brand;
  final String title;
  final String body;
  final String cta;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;
  final String? infoLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final img = image;
    return Semantics(
      container: true,
      label: '$sponsoredLabel: $brand',
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.lg),
          side: BorderSide(color: cs.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (img != null) _PromoImage(image: img, aspect: 2.6),
              Padding(
                padding: const EdgeInsets.fromLTRB(CsSpace.md, 4, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CsSponsoredLabel(
                      label: sponsoredLabel,
                      brand: brand,
                      onInfo: onInfo,
                      infoLabel: infoLabel,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodySmall?.copyWith(
                                      color: cs.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (cta.isNotEmpty && onTap != null) ...[
                            const SizedBox(width: CsSpace.sm),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: onTap,
                              child: Text(cta),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Campus feed ad: drawn as a post (the brand's logo as the avatar, its
/// name, "Sponsored"), with the picture and one button where a post's
/// reactions would be. No comments, likes or report.
class CsPromoFeedPost extends StatelessWidget {
  const CsPromoFeedPost({
    super.key,
    required this.sponsoredLabel,
    required this.brand,
    required this.title,
    this.body = '',
    this.cta = '',
    this.logo,
    this.image,
    this.onTap,
    this.onInfo,
    this.infoLabel,
  });

  final String sponsoredLabel;
  final String brand;
  final String title;
  final String body;
  final String cta;
  final ImageProvider? logo;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;
  final String? infoLabel;

  @override
  Widget build(BuildContext context) {
    final img = image;
    return Semantics(
      container: true,
      label: '$sponsoredLabel: $brand',
      child: CsPostCard(
        onTap: onTap,
        header: CsPostHeader(
          avatar: CsBrandLogo(name: brand, logo: logo, size: 42, round: true),
          name: brand,
          subtitle: sponsoredLabel,
          trailing: onInfo == null
              ? null
              : _InfoButton(onTap: onInfo!, label: infoLabel ?? sponsoredLabel),
        ),
        title: title,
        text: body,
        maxLines: 3,
        media: img == null
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CsRadius.md),
                  child: _PromoImage(image: img),
                ),
              ),
        actions: cta.isEmpty || onTap == null
            ? const SizedBox(height: CsSpace.xs)
            : Padding(
                padding: const EdgeInsets.fromLTRB(
                  CsSpace.md,
                  CsSpace.sm,
                  CsSpace.md,
                  CsSpace.xs,
                ),
                child: FilledButton.tonal(onPressed: onTap, child: Text(cta)),
              ),
      ),
    );
  }
}

/// A student deal: logo, brand, the offer, a line, the code with Copy, the
/// last day, and the terms behind a tap.
class CsDealCard extends StatefulWidget {
  const CsDealCard({
    super.key,
    required this.brand,
    required this.title,
    required this.sponsoredLabel,
    this.body = '',
    this.logo,
    this.code,
    this.copyLabel = 'Copy',
    this.onCopy,
    this.until,
    this.terms = '',
    this.termsLabel = 'Terms',
    this.visitLabel = 'Visit',
    this.onVisit,
    this.onInfo,
    this.infoLabel,
  });

  final String brand;
  final String title;
  final String sponsoredLabel;
  final String body;
  final ImageProvider? logo;
  final String? code;
  final String copyLabel;
  final VoidCallback? onCopy;

  /// "Until 31 Dec".
  final String? until;
  final String terms;
  final String termsLabel;
  final String visitLabel;
  final VoidCallback? onVisit;
  final VoidCallback? onInfo;
  final String? infoLabel;

  @override
  State<CsDealCard> createState() => _CsDealCardState();
}

class _CsDealCardState extends State<CsDealCard> {
  bool _terms = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final w = widget;
    final code = w.code;
    return Semantics(
      container: true,
      label: '${w.sponsoredLabel}: ${w.brand}',
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.lg),
          side: BorderSide(color: cs.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CsSpace.md, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsBrandLogo(name: w.brand, logo: w.logo, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand and the ⓘ on one line.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            w.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelMedium?.copyWith(
                              color: cs.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (w.onInfo != null)
                          _InfoButton(
                            onTap: w.onInfo!,
                            label: w.infoLabel ?? w.sponsoredLabel,
                          )
                        else
                          const SizedBox(height: 36),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.title,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (w.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              w.body,
                              style: context.text.bodySmall?.copyWith(
                                color: cs.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (code != null) ...[
                                _CodeChip(
                                  code: code,
                                  copyLabel: w.copyLabel,
                                  onCopy: w.onCopy,
                                ),
                                const SizedBox(width: CsSpace.sm),
                              ],
                              Expanded(
                                child: Text(
                                  w.until ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.labelSmall?.copyWith(
                                    color: cs.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (w.terms.isNotEmpty || w.onVisit != null)
                            Row(
                              children: [
                                if (w.terms.isNotEmpty)
                                  _TextLink(
                                    label: w.termsLabel,
                                    icon: _terms
                                        ? CsIcons.chevronUp
                                        : CsIcons.chevronDown,
                                    onTap: () =>
                                        setState(() => _terms = !_terms),
                                  ),
                                const Spacer(),
                                if (w.onVisit != null)
                                  _TextLink(
                                    label: w.visitLabel,
                                    icon: CsIcons.openExternal,
                                    onTap: w.onVisit!,
                                  ),
                              ],
                            ),
                          AnimatedSize(
                            duration: CsMotion.normal,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: _terms
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      w.terms,
                                      style: context.text.bodySmall?.copyWith(
                                        color: cs.textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The promo code in a dashed amber box, with Copy.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.copyLabel, this.onCopy});

  final String code;
  final String copyLabel;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return Semantics(
      button: true,
      label: '$copyLabel $code',
      child: Material(
        color: amber.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CsRadius.sm),
          side: BorderSide(color: amber.withValues(alpha: 0.55)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onCopy,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(CsIcons.copy, size: 16, color: amber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CsRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(icon, size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

/// One quiet line at the bottom of a page: "Supported by [logo] Brand".
class CsSponsorLine extends StatelessWidget {
  const CsSponsorLine({
    super.key,
    required this.label,
    required this.brand,
    this.logo,
    this.onTap,
    this.onLongPress,
  });

  /// "Supported by".
  final String label;
  final String brand;
  final ImageProvider? logo;
  final VoidCallback? onTap;

  /// Opens the Why / Hide sheet (a line has no room for an ⓘ).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(CsRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: cs.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              CsBrandLogo(name: brand, logo: logo, size: 18),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Powered by [logo] Brand", a small glass chip for a campaign's poster.
class CsPoweredBy extends StatelessWidget {
  const CsPoweredBy({
    super.key,
    required this.label,
    required this.brand,
    this.logo,
  });

  /// "Powered by".
  final String label;
  final String brand;
  final ImageProvider? logo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
    decoration: BoxDecoration(
      color: const Color(0x66020617),
      borderRadius: BorderRadius.circular(CsRadius.full),
      border: Border.all(color: const Color(0x40FFFFFF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(width: 5),
        CsBrandLogo(name: brand, logo: logo, size: 16, round: true),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
