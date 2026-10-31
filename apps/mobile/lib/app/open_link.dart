import 'dart:async';

import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'env.dart';

/// What a tapped link in text does (CsLinkText): our own invite, post and
/// blood request links open inside the app; anything else opens in the browser, mail
/// app or dialer. A link that can't be opened says so.
void Function(BuildContext, Uri) linkOpener(GoRouter router) => (context, uri) {
  final site = Uri.parse(Env.siteUrl).host;
  final host = uri.host.toLowerCase();
  final path = uri.path;
  if ((host == site || host == 'www.$site') &&
      (path.startsWith('/join/') ||
          path.startsWith('/c/') ||
          path.startsWith('/blood/') ||
          path.startsWith('/v/'))) {
    unawaited(router.push(path));
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = AppLocalizations.of(context).openLinkFailed;
  unawaited(() async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      ok = false;
    }
    if (!ok) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }());
};
