import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:intl/intl.dart';

import '../../classes/presentation/class_format.dart';

/// A badge's name; keys this app doesn't know yet read as a plain title.
String badgeName(AppLocalizations l10n, String key) => switch (key) {
  'verified' => l10n.badgeNameVerified,
  'founding' => l10n.badgeNameFounding,
  'cr' => l10n.badgeNameCr,
  'campus_admin' => l10n.badgeNameCampusAdmin,
  'bus_rep' => l10n.badgeNameBusRep,
  'official' => l10n.badgeNameOfficial,
  'blood_donor' => l10n.badgeNameBloodDonor,
  'life_saver' => l10n.badgeNameLifeSaver,
  'bus_buddy' => l10n.badgeNameBusBuddy,
  'section_builder' => l10n.badgeNameSectionBuilder,
  'connector' => l10n.badgeNameConnector,
  'bug_hunter' => l10n.badgeNameBugHunter,
  'helper' => l10n.badgeNameHelper,
  'campus_voice' => l10n.badgeNameCampusVoice,
  _ => key.replaceAll('_', ' '),
};

/// How to earn a badge.
String badgeHow(AppLocalizations l10n, String key) => switch (key) {
  'verified' => l10n.badgeHowVerified,
  'founding' => l10n.badgeHowFounding,
  'cr' => l10n.badgeHowCr,
  'campus_admin' => l10n.badgeHowCampusAdmin,
  'bus_rep' => l10n.badgeHowBusRep,
  'official' => l10n.badgeHowOfficial,
  'blood_donor' => l10n.badgeHowBloodDonor,
  'life_saver' => l10n.badgeHowLifeSaver,
  'bus_buddy' => l10n.badgeHowBusBuddy,
  'section_builder' => l10n.badgeHowSectionBuilder,
  'connector' => l10n.badgeHowConnector,
  'bug_hunter' => l10n.badgeHowBugHunter,
  'helper' => l10n.badgeHowHelper,
  'campus_voice' => l10n.badgeHowCampusVoice,
  _ => '',
};

/// "Bronze", "Silver" or "Gold"; null for badges without tiers.
String? tierName(AppLocalizations l10n, int tier) => switch (tier) {
  1 => l10n.badgeTierBronze,
  2 => l10n.badgeTierSilver,
  3 => l10n.badgeTierGold,
  _ => null,
};

/// The tier thresholds ("Bronze 1 · Silver 10 · Gold 30"), or null.
String? tiersLine(AppLocalizations l10n, List<int> tiers) => tiers.length == 3
    ? l10n.badgeTiersLine(tiers[0], tiers[1], tiers[2])
    : null;

/// A role on a profile (`cr`, `campus_admin`…); null for unknown ones.
String? roleName(AppLocalizations l10n, String role) => switch (role) {
  'cr' => l10n.roleCr,
  'campus_admin' => l10n.roleCampusAdmin,
  'bus_rep' => l10n.roleBusRep,
  'official' => l10n.roleOfficial,
  _ => null,
};

/// Month and year in the app's language ("October 2026").
String monthYear(AppLocalizations l10n, DateTime d) =>
    DateFormat.yMMMM(l10n.localeName).format(d);

/// Badges, profiles and campaigns errors in plain words; anything else
/// falls back to the group errors.
String growthErrorText(AppLocalizations l10n, Failure f) {
  return switch (f.code) {
    'BADGE_NOT_HELD' => l10n.badgeNotHeld,
    'BADGE_PRIVATE' => l10n.badgePrivateCant,
    'NOT_A_WINNER' => l10n.claimNotWinner,
    _ => classErrorText(l10n, f),
  };
}

/// "5d 3h left", "2h 10m left" or "9 min left"; null once over.
String? timeLeftText(AppLocalizations l10n, DateTime end, DateTime now) {
  final left = end.difference(now);
  if (left.isNegative || left == Duration.zero) return null;
  if (left.inDays >= 1) {
    return l10n.campaignLeftDays(left.inDays, left.inHours % 24);
  }
  if (left.inHours >= 1) {
    return l10n.campaignLeftHours(left.inHours, left.inMinutes % 60);
  }
  return l10n.campaignLeftMinutes(left.inMinutes < 1 ? 1 : left.inMinutes);
}

/// "Rank 3 · 12 invites" or the nudge to invite when not ranked.
String campaignStanding(AppLocalizations l10n, Campaign c) => c.myRank == null
    ? l10n.campaignNoRank
    : l10n.campaignMyRank(c.myRank!, l10n.campaignScore(c.myScore));

/// A prize's rank or range ("Rank 1", "Ranks 4–10").
String prizeRankText(AppLocalizations l10n, CampaignPrize p) => p.isRange
    ? l10n.campaignPrizeRange(p.rankFrom, p.rankTo)
    : l10n.campaignPrizeRank(p.rankFrom);
