import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';

import '../../classes/presentation/class_format.dart';

/// Why someone can't vouch, in plain words. [name] is the student asking.
String vouchReasonText(AppLocalizations l10n, VouchReason r, String name) =>
    switch (r) {
      VouchReason.self => l10n.vouchReasonSelf,
      VouchReason.notVerified => l10n.vouchReasonNotVerified,
      VouchReason.otherUniversity => l10n.vouchReasonOther,
      VouchReason.blocked => l10n.vouchReasonBlocked,
      VouchReason.limit => l10n.vouchReasonLimit,
      VouchReason.alreadyVerified => l10n.vouchReasonAlreadyVerified(name),
    };

/// Verification, vouching, confirming and campus-admin errors in plain
/// words; anything else falls back to the group errors.
String verificationErrorText(
  AppLocalizations l10n,
  Failure f, {
  String name = '',
}) {
  final reason = VouchReason.fromErrorCode(f.code);
  if (reason != null) return vouchReasonText(l10n, reason, name);
  return switch (f.code) {
    'VOUCH_NOT_FOUND' => l10n.vouchNotFound,
    'NOT_CR' => l10n.confirmNotCr,
    'CONFIRM_LIMIT' => l10n.confirmLimit,
    'EMAIL_VERIFIED' => l10n.caEmailVerifiedNote,
    'NOT_CAMPUS_ADMIN' => l10n.caNotAdmin,
    'FEEDBACK_LIMIT' => l10n.feedbackLimit,
    'FEEDBACK_NOT_FOUND' => l10n.feedbackNotFound,
    _ => classErrorText(l10n, f),
  };
}

/// How the student got verified.
String verifiedViaText(AppLocalizations l10n, VerifiedVia? via) =>
    switch (via) {
      VerifiedVia.email || null => l10n.verifiedViaEmail,
      VerifiedVia.cr => l10n.verifiedViaCr,
      VerifiedVia.vouch => l10n.verifiedViaVouch,
      VerifiedVia.campusAdmin => l10n.verifiedViaCampusAdmin,
      VerifiedVia.admin => l10n.verifiedViaAdmin,
    };
