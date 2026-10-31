import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';

import '../verification_text.dart';

/// Loads something once and shows it: a spinner, then [builder], or the
/// failure in plain words with "Try again". [builder] gets a `reload` to
/// call after a change.
class LoadView<T> extends StatefulWidget {
  const LoadView({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;

  @override
  State<LoadView<T>> createState() => _LoadViewState<T>();
}

class _LoadViewState<T> extends State<LoadView<T>> {
  T? _data;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final d = await widget.load();
      if (mounted) {
        setState(() {
          _data = d;
          _failure = null;
        });
      }
    } on Failure catch (f) {
      if (mounted) setState(() => _failure = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _data;
    if (data is T && _failure == null) {
      return widget.builder(context, data, _reload);
    }
    if (_failure case final f?) {
      return CsEmptyState(
        icon: CsIcons.offline,
        title: verificationErrorText(l10n, f),
        actionLabel: l10n.tryAgain,
        onAction: () {
          setState(() => _failure = null);
          _reload();
        },
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
