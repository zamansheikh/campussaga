import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/cs_tokens.dart';

/// A link found in text: where it is and what it opens.
class CsLink {
  const CsLink(this.start, this.end, this.uri);

  final int start;
  final int end;
  final Uri uri;

  @override
  String toString() => 'CsLink($start, $end, $uri)';
}

/// Finds what people write as links: web addresses (with or without
/// `https://`, like `forms.gle/abc` or `ju.ac.bd`), email addresses and
/// Bangladeshi mobile numbers.
abstract final class CsLinks {
  // Endings a bare address (no https://, no www.) must have, so "e.g." or
  // "3.5" never become links.
  static const _tlds =
      'com|net|org|edu|gov|bd|io|me|ly|gle|co|info|app|dev|link|xyz|site|'
      'page|ai|in|us|uk|tv|gg|to';

  static final _re = RegExp(
    // email
    r'([A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})'
    // https://… or www.…
    r'|((?:https?://|www\.)[^\s<>"]+)'
    // a bare address: name.tld or a.b.tld, then an optional path
    '|(\\b(?:[A-Za-z0-9-]+\\.)+(?:$_tlds)\\b(?:/[^\\s<>"]*)?)'
    // a mobile number: 01XXXXXXXXX, +8801XXXXXXXXX
    r'|((?<![\d+])(?:\+?88)?01[3-9]\d{8}(?!\d))',
    caseSensitive: false,
  );

  static const _trailing = '.,;:!?\'"»”’)]}';

  /// The links in [text], in order.
  static List<CsLink> find(String text) {
    final out = <CsLink>[];
    for (final m in _re.allMatches(text)) {
      var raw = m[0]!;
      // Punctuation after a link belongs to the sentence ("see x.com.").
      while (raw.isNotEmpty && _trailing.contains(raw[raw.length - 1])) {
        final last = raw[raw.length - 1];
        if (last == ')' &&
            '('.allMatches(raw).length >= ')'.allMatches(raw).length) {
          break; // a link with its own (…), like a Wikipedia page
        }
        raw = raw.substring(0, raw.length - 1);
      }
      if (raw.isEmpty) continue;
      final Uri? uri;
      if (m[1] != null) {
        uri = Uri(scheme: 'mailto', path: raw);
      } else if (m[4] != null) {
        uri = Uri(scheme: 'tel', path: raw);
      } else {
        final lower = raw.toLowerCase();
        uri = Uri.tryParse(
          lower.startsWith('http://') || lower.startsWith('https://')
              ? raw
              : 'https://$raw',
        );
      }
      if (uri == null || (uri.scheme.startsWith('http') && uri.host.isEmpty)) {
        continue;
      }
      out.add(CsLink(m.start, m.start + raw.length, uri));
    }
    return out;
  }
}

/// Text whose links, email addresses and phone numbers can be tapped.
/// What a tap does is set once for the whole app with [onOpen] (open the
/// browser, the mail app or the dialer). Without links it is plain text.
class CsLinkText extends StatefulWidget {
  const CsLinkText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.selectable = false,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Long-press to select and copy (opened posts, announcements).
  final bool selectable;

  /// Opens a tapped link; set at app start.
  static void Function(BuildContext context, Uri uri)? onOpen;

  @override
  State<CsLinkText> createState() => _CsLinkTextState();
}

class _CsLinkTextState extends State<CsLinkText> {
  List<CsLink> _links = const [];
  final _taps = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(CsLinkText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _parse();
  }

  void _parse() {
    _disposeTaps();
    _links = CsLinks.find(widget.text);
    for (final l in _links) {
      _taps.add(
        TapGestureRecognizer()
          ..onTap = () => CsLinkText.onOpen?.call(context, l.uri),
      );
    }
  }

  void _disposeTaps() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _disposeTaps();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    if (_links.isEmpty) {
      return widget.selectable
          ? SelectableText(
              text,
              style: widget.style,
              maxLines: widget.maxLines,
              textAlign: widget.textAlign,
            )
          : Text(
              text,
              style: widget.style,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
              textAlign: widget.textAlign,
            );
    }
    final cs = context.cs;
    final linkStyle = (widget.style ?? DefaultTextStyle.of(context).style)
        .copyWith(
          color: cs.primary,
          decoration: TextDecoration.underline,
          decorationColor: cs.primary.withValues(alpha: 0.6),
        );
    final spans = <InlineSpan>[];
    var at = 0;
    for (var i = 0; i < _links.length; i++) {
      final l = _links[i];
      if (l.start > at) spans.add(TextSpan(text: text.substring(at, l.start)));
      spans.add(
        TextSpan(
          text: text.substring(l.start, l.end),
          style: linkStyle,
          recognizer: _taps[i],
          semanticsLabel: text.substring(l.start, l.end),
        ),
      );
      at = l.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    final span = TextSpan(style: widget.style, children: spans);
    return widget.selectable
        ? SelectableText.rich(
            span,
            maxLines: widget.maxLines,
            textAlign: widget.textAlign,
          )
        : Text.rich(
            span,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
            textAlign: widget.textAlign,
          );
  }
}
