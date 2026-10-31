import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../classes/data/invite_link.dart';
import 'growth_text.dart';

/// Hands text to the phone's share sheet. A variable so tests can see what
/// would be shared.
Future<void> Function(String text, Rect? origin) inviteShare =
    (text, origin) async {
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
    };

Rect? _originOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}

/// The message with my personal link, in the app's language.
String inviteMessage(AppLocalizations l10n, ReferralStats stats) {
  final link = stats.link.isNotEmpty
      ? stats.link
      : InviteLink.personalLink(stats.code).toString();
  return l10n.inviteShareText(l10n.appName, link);
}

/// Shares my personal invite link. Fetches the link first unless [stats]
/// is at hand; says so if it can't be fetched.
Future<void> shareMyInvite(BuildContext context, {ReferralStats? stats}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final origin = _originOf(context);
  try {
    final s = stats ?? await getIt<GrowthRepository>().referrals();
    await inviteShare(inviteMessage(l10n, s), origin);
  } on Failure catch (f) {
    messenger.showSnackBar(SnackBar(content: Text(growthErrorText(l10n, f))));
  }
}

/// My personal invite code, for the class invite links (`?ref=`): from the
/// profile when it has one, else asked of the server. Null when it can't
/// be had (the link then goes without it).
Future<String?> myReferralCode(BuildContext context) async {
  final fromProfile = context.read<AuthBloc>().state.user?.referralCode;
  if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
  if (!getIt.isRegistered<GrowthRepository>()) return null;
  try {
    final code = (await getIt<GrowthRepository>().referrals()).code;
    return code.isEmpty ? null : code;
  } on Failure {
    return null;
  }
}
