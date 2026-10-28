import 'dart:typed_data';

import 'voice_models.dart';

/// Campus Voice API (docs/CAMPUS_VOICE.md §4). Every call throws a
/// `Failure`; codes the app shows are mapped in the voice feature.
abstract interface class VoiceRepository {
  /// The university's feed. [private] lists safety issues (officials only).
  Future<VoicePage<IssueCard>> feed({
    IssueSort sort = IssueSort.trending,
    IssueCategory? category,
    String? query,
    String? cursor,
    bool private = false,
  });

  /// Up to 5 issues like this title (before posting).
  Future<List<IssueCard>> similar(String title);

  Future<Issue> issue(String id);

  Future<Issue> create(IssueDraft draft);

  /// Within 60 minutes of posting (the author).
  Future<Issue> edit(
    String id, {
    String? title,
    String? body,
    String? locationLabel,
  });

  Future<void> delete(String id);

  /// Me too on/off: the new count.
  Future<({int meTooCount, bool voted})> vote(String id, {required bool on});

  Future<bool> follow(String id, {required bool on});

  /// The author reopens a solved issue.
  Future<Issue> reopen(String id, String note);

  Future<VoicePage<IssueComment>> comments(String issueId, {String? cursor});

  Future<IssueComment> addComment(
    String issueId,
    String body, {
    bool anonymous = true,
  });

  Future<void> deleteComment(String issueId, String commentId);

  Future<void> report(
    String issueId,
    ReportReason reason, {
    String details = '',
  });

  Future<void> reportComment(
    String issueId,
    String commentId,
    ReportReason reason, {
    String details = '',
  });

  /// The caller's own issues, every state, newest first.
  Future<VoicePage<IssueCard>> myIssues({String? cursor});

  /// One photo (already compressed on the phone).
  Future<VoiceUpload> upload(
    Uint8List bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  });

  /// An issue photo (or the caller's own unattached upload).
  Future<Uint8List> image(String imageId, {bool thumb = false});

  /// Officials: move the issue to [to].
  Future<Issue> changeStatus(String id, IssueStatus to, {String note = ''});

  /// Officials: a public reply with their title.
  Future<IssueComment> officialReply(String issueId, String body);
}
