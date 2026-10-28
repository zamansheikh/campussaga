import 'dart:async';

import 'package:campus_core/campus_core.dart';

/// An issue changed on its own page (me too, follow, comment, status) or
/// was deleted; lists showing it follow.
sealed class VoiceUpdate {
  const VoiceUpdate();
}

final class IssueChanged extends VoiceUpdate {
  const IssueChanged(this.card);
  final IssueCard card;
}

final class IssueDeleted extends VoiceUpdate {
  const IssueDeleted(this.id);
  final String id;
}

/// App-wide, for the lists open behind an issue page.
final voiceUpdates = StreamController<VoiceUpdate>.broadcast();
