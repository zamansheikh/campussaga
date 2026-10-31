import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';

String feedbackKindLabel(AppLocalizations l10n, FeedbackKind k) => switch (k) {
  FeedbackKind.bug => l10n.feedbackKindBug,
  FeedbackKind.idea => l10n.feedbackKindIdea,
  FeedbackKind.other => l10n.feedbackKindOther,
};

String feedbackStatusLabel(AppLocalizations l10n, FeedbackStatus s) =>
    switch (s) {
      FeedbackStatus.fresh => l10n.feedbackStatusNew,
      FeedbackStatus.seen => l10n.feedbackStatusSeen,
      FeedbackStatus.planned => l10n.feedbackStatusPlanned,
      FeedbackStatus.inProgress => l10n.feedbackStatusInProgress,
      FeedbackStatus.done => l10n.feedbackStatusDone,
      FeedbackStatus.wontDo => l10n.feedbackStatusWontDo,
    };
