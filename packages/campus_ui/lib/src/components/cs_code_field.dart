import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/cs_tokens.dart';
import '../tokens/dimensions.dart';

/// One-time code input drawn as [length] boxes. A single hidden text field
/// does the typing, so paste and SMS / email code autofill keep working.
class CsCodeField extends StatefulWidget {
  const CsCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
    this.semanticLabel,
    this.letters = false,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool hasError;
  final bool autofocus;
  final String? semanticLabel;

  /// Letters (shown in capitals) instead of digits, e.g. a join code.
  final bool letters;

  @override
  State<CsCodeField> createState() => _CsCodeFieldState();
}

class _CsCodeFieldState extends State<CsCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final text = widget.controller.text;
    final active = _focus.hasFocus
        ? text.length.clamp(0, widget.length - 1)
        : -1;
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focus.requestFocus(),
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) SizedBox(width: i == widget.length ~/ 2 ? 14 : 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: CsMotion.fast,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.enabled ? cs.surface : cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(CsRadius.md),
                        border: Border.all(
                          width: (i == active || widget.hasError) ? 2 : 1,
                          color: widget.hasError
                              ? cs.error
                              : i == active
                              ? cs.primary
                              : cs.border,
                        ),
                      ),
                      child: Text(
                        i < text.length ? text[i] : '',
                        style: context.text.headlineSmall,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // The real input: invisible, on top, so taps and paste land here.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  keyboardType: widget.letters
                      ? TextInputType.text
                      : TextInputType.number,
                  textCapitalization: widget.letters
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: widget.letters
                      ? null
                      : const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    if (widget.letters) ...[
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                      _UpperCase(),
                    ] else
                      FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    filled: false,
                  ),
                  onChanged: (v) {
                    if (v.length == widget.length) widget.onCompleted?.call(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
