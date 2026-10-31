import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/widgets.dart';

import 'package:intl/intl.dart';

import '../../auth/presentation/auth_error_text.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// A count in the app's language (Bangla digits in Bangla).
String countText(BuildContext context, int n) =>
    NumberFormat.decimalPattern(_locale(context)).format(n);

String categoryLabel(AppLocalizations l10n, IssueCategory c) => switch (c) {
  IssueCategory.academic => l10n.voiceCatAcademic,
  IssueCategory.hostel => l10n.voiceCatHostel,
  IssueCategory.transport => l10n.voiceCatTransport,
  IssueCategory.facilities => l10n.voiceCatFacilities,
  IssueCategory.safety => l10n.voiceCatSafety,
  IssueCategory.administration => l10n.voiceCatAdministration,
  IssueCategory.food => l10n.voiceCatFood,
  IssueCategory.it => l10n.voiceCatIt,
  IssueCategory.other => l10n.voiceCatOther,
  IssueCategory.general => l10n.voiceCatGeneral,
  IssueCategory.event => l10n.voiceCatEvent,
  IssueCategory.lostFound => l10n.voiceCatLostFound,
  IssueCategory.buySell => l10n.voiceCatBuySell,
  IssueCategory.fun => l10n.voiceCatFun,
};

String kindLabel(AppLocalizations l10n, PostKind k) => switch (k) {
  PostKind.post => l10n.campusKindPost,
  PostKind.question => l10n.campusKindQuestion,
  PostKind.poll => l10n.campusKindPoll,
  PostKind.issue => l10n.campusKindIssue,
};

IconData kindIcon(PostKind k) => switch (k) {
  PostKind.post => CsIcons.post,
  PostKind.question => CsIcons.question,
  PostKind.poll => CsIcons.poll,
  PostKind.issue => CsIcons.raiseIssue,
};

String reactionLabel(AppLocalizations l10n, Reaction r) => switch (r) {
  Reaction.meToo => l10n.voiceMeToo,
  Reaction.like => l10n.reactLike,
  Reaction.haha => l10n.reactHaha,
  Reaction.wow => l10n.reactWow,
  Reaction.sad => l10n.reactSad,
  Reaction.clap => l10n.reactClap,
};

/// "42%" in the app's language.
String percentText(BuildContext context, double share) =>
    NumberFormat.percentPattern(_locale(context)).format(share);

/// What a poll's footer says: votes, and the time left or "Final results".
String pollFooter(BuildContext context, Poll poll, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final votes = l10n.campusPollVotes(poll.totalVotes);
  final String when;
  if (poll.isClosed(now)) {
    when = l10n.campusPollFinal;
  } else {
    final left = poll.closesAt.difference(now);
    when = left.inHours >= 24
        ? l10n.campusPollDaysLeft((left.inHours / 24).ceil())
        : left.inHours >= 1
        ? l10n.campusPollHoursLeft(left.inHours)
        : l10n.campusPollEndingSoon;
  }
  final hint = !poll.resultsShown && !poll.isClosed(now)
      ? ' · ${l10n.campusPollVoteToSee}'
      : '';
  return '$votes · $when$hint';
}

/// A post's words for sharing and pushes: the title of an issue, else the
/// start of the text.
String postSnippet(IssueCard c, {int max = 100}) {
  final t = (c.isIssue && c.title.isNotEmpty ? c.title : c.preview).trim();
  final chars = t.characters;
  return chars.length <= max ? t : '${chars.take(max - 1)}…';
}

String statusLabel(AppLocalizations l10n, IssueStatus s) => switch (s) {
  IssueStatus.open => l10n.voiceStatusOpen,
  IssueStatus.acknowledged => l10n.voiceStatusAcknowledged,
  IssueStatus.inProgress => l10n.voiceStatusInProgress,
  IssueStatus.solved => l10n.voiceStatusSolved,
  IssueStatus.rejected => l10n.voiceStatusRejected,
};

CsIssueTone statusTone(IssueStatus s) => switch (s) {
  IssueStatus.open => CsIssueTone.open,
  IssueStatus.acknowledged => CsIssueTone.acknowledged,
  IssueStatus.inProgress => CsIssueTone.inProgress,
  IssueStatus.solved => CsIssueTone.solved,
  IssueStatus.rejected => CsIssueTone.rejected,
};

/// The chip an issue shows: its status, or (author/staff only) that it is
/// under review or removed.
Widget issueChip(AppLocalizations l10n, IssueCard c) => switch (c.visibility) {
  ContentVisibility.removed => CsStatusChip(
    tone: CsIssueTone.removed,
    label: l10n.voiceRemoved,
  ),
  ContentVisibility.held || ContentVisibility.hidden => CsStatusChip(
    tone: CsIssueTone.review,
    label: l10n.voiceUnderReview,
  ),
  ContentVisibility.visible => CsStatusChip(
    tone: statusTone(c.status),
    label: statusLabel(l10n, c.status),
  ),
};

/// How the author appears: "You" on the caller's own, the name on a named
/// post, otherwise "Anonymous". Never anything else.
String issueAuthorLabel(AppLocalizations l10n, IssueCard c) {
  if (c.mine) return l10n.voiceYou;
  final a = c.author;
  if (a == null) return l10n.voiceAnonymous;
  return a.name.isEmpty ? l10n.voiceDeletedAccount : a.name;
}

/// "Student 7KQF", "Author", a name, or an official's name.
String commentWho(AppLocalizations l10n, IssueComment c) {
  final a = c.author;
  if (c.official) {
    return a == null || a.name.isEmpty ? l10n.voiceOfficial : a.name;
  }
  if (a != null) return a.name.isEmpty ? l10n.voiceDeletedAccount : a.name;
  if (c.isIssueAuthor) return l10n.voiceAuthorTag;
  return c.handle.isEmpty ? l10n.voiceAnonymous : l10n.voiceHandle(c.handle);
}

String holdReasonText(AppLocalizations l10n, String reason) => switch (reason) {
  'personal_info' => l10n.voiceHeldPersonalInfo,
  'language' => l10n.voiceHeldLanguage,
  'unverified' => l10n.voiceHeldUnverified,
  'moderator' => l10n.voiceHeldModerator,
  'photo_check' || 'photo_check_unavailable' => l10n.voiceHeldPhoto,
  _ => '',
};

String reportReasonLabel(AppLocalizations l10n, ReportReason r) => switch (r) {
  ReportReason.spam => l10n.voiceReportSpam,
  ReportReason.abuse => l10n.voiceReportAbuse,
  ReportReason.personalInfo => l10n.voiceReportPersonalInfo,
  ReportReason.falseInfo => l10n.voiceReportFalseInfo,
  ReportReason.inappropriate => l10n.voiceReportInappropriate,
  ReportReason.other => l10n.voiceReportOther,
};

/// Who made a status change, as students see it.
String actorLabel(AppLocalizations l10n, TimelineEntry e) => switch (e.actor) {
  TimelineActor.authority =>
    e.actorTitle.isEmpty ? l10n.voiceOfficial : e.actorTitle,
  TimelineActor.moderator => l10n.voiceActorModerator,
  TimelineActor.author => l10n.voiceActorAuthor,
  TimelineActor.system => l10n.voiceActorSystem,
};

/// "28 Oct" (Bangla digits in Bangla).
String shortDay(BuildContext context, DateTime t) =>
    DateFormat.MMMd(_locale(context)).format(t);

/// Campus Voice errors in plain words.
String voiceErrorText(BuildContext context, Failure f) {
  final l10n = AppLocalizations.of(context);
  return switch (f.code) {
    'FEATURE_DISABLED' => l10n.errorFeatureDisabled,
    'VOICE_BANNED' => _bannedText(context, f),
    'ISSUE_NOT_FOUND' => l10n.errorIssueNotFound,
    'COMMENT_NOT_FOUND' => l10n.errorCommentNotFound,
    'UPLOAD_NOT_FOUND' => l10n.errorUploadNotFound,
    'IMAGE_INVALID' => l10n.errorImageInvalid,
    'IMAGE_TOO_LARGE' => l10n.errorImageTooLarge,
    'PHOTO_NOT_ALLOWED' => l10n.errorPhotoNotAllowed,
    'EDIT_WINDOW_CLOSED' => l10n.errorEditWindowClosed,
    'REOPEN_NOT_ALLOWED' => l10n.errorReopenNotAllowed,
    'ISSUE_CLOSED' => l10n.errorIssueClosed,
    'CANNOT_VOTE_OWN' => l10n.errorCannotVoteOwn,
    'ALREADY_REPORTED' => l10n.errorAlreadyReported,
    'STATUS_CHANGE_INVALID' => l10n.errorStatusChangeInvalid,
    'NOTE_REQUIRED' => l10n.errorNoteRequired,
    'UNIVERSITY_REQUIRED' => l10n.errorUniversityRequired,
    'POLL_CLOSED' => l10n.errorPollClosed,
    'ALREADY_VOTED' => l10n.errorAlreadyVoted,
    'NOT_AN_ISSUE' => l10n.errorNotAnIssue,
    _ when f is RateLimitedFailure => l10n.errorTooManyRequests,
    _ => authErrorText(l10n, f),
  };
}

String _bannedText(BuildContext context, Failure f) {
  final l10n = AppLocalizations.of(context);
  DateTime? t;
  if (f is RejectedFailure) {
    final until = f.details?['until'];
    if (until is String) t = DateTime.tryParse(until)?.toLocal();
  }
  if (t == null) return l10n.errorVoiceBanned;
  return l10n.errorVoiceBannedUntil(
    DateFormat.yMMMd(_locale(context)).format(t),
  );
}
