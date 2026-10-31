import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/clock.dart';
import '../../../app/env.dart';
import '../../auth/presentation/auth_error_text.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "Today, 3:00 PM", "Tomorrow, 10:00 AM" or "Wed, Nov 4, 10:00 AM".
String bloodWhenText(BuildContext context, DateTime at) {
  final l10n = AppLocalizations.of(context);
  final t = at.toLocal();
  final time = DateFormat.jm(_locale(context)).format(t);
  final today = DateUtils.dateOnly(appNow());
  final day = DateUtils.dateOnly(t);
  if (day == today) return l10n.bloodToday(time);
  if (day == today.add(const Duration(days: 1))) {
    return l10n.bloodTomorrow(time);
  }
  return '${DateFormat.MMMEd(_locale(context)).format(t)}, $time';
}

/// "4 Nov 2026" style for donor dates.
String bloodDateText(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(_locale(context)).format(d);

String bloodStatusText(AppLocalizations l10n, BloodRequestStatus s) =>
    switch (s) {
      BloodRequestStatus.open => '',
      BloodRequestStatus.fulfilled => l10n.bloodStatusFulfilled,
      BloodRequestStatus.closed => l10n.bloodStatusClosed,
      BloodRequestStatus.expired => l10n.bloodStatusExpired,
    };

/// "A+ · A− · O+ · O−" (the groups a patient can receive from).
String compatibleText(BloodGroup g) =>
    [for (final x in g.canReceiveFrom) x.label].join(' · ');

/// The text shared to WhatsApp or Facebook groups.
String bloodShareText(BuildContext context, BloodRequest r) {
  final l10n = AppLocalizations.of(context);
  final place = [r.hospital, if (r.area.isNotEmpty) r.area].join(', ');
  return [
    '${l10n.bloodShareIntro(r.bloodGroup.label)} (${l10n.bloodUnits(r.units)})',
    '🏥 $place',
    '🕒 ${bloodWhenText(context, r.neededBy)}'
        '${r.urgent ? ' · ${l10n.bloodUrgent}' : ''}',
    '📞 ${r.contactName}: ${r.contactPhone}',
    if (r.note.isNotEmpty) r.note,
    '',
    l10n.bloodShareVia('${Env.siteUrl}/blood/${r.id}'),
  ].join('\n');
}

/// Blood donation errors in plain words.
String bloodErrorText(BuildContext context, Failure f) {
  final l10n = AppLocalizations.of(context);
  return switch (f.code) {
    'VERIFY_REQUIRED' => l10n.errorVerifyRequired,
    'TOO_MANY_OPEN_REQUESTS' => l10n.errorTooManyOpenRequests,
    'BLOOD_REQUEST_NOT_FOUND' => l10n.errorBloodRequestNotFound,
    'REQUEST_CLOSED' => l10n.errorRequestClosed,
    'CANNOT_RESPOND_OWN' => l10n.errorCannotRespondOwn,
    'DONOR_REQUIRED' => l10n.errorDonorRequired,
    'UNIVERSITY_REQUIRED' => l10n.errorUniversityRequired,
    _ when f is RateLimitedFailure => l10n.errorTooManyRequests,
    _ => authErrorText(l10n, f),
  };
}
