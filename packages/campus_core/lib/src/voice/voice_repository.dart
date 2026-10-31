import 'dart:typed_data';

import 'voice_models.dart';

/// The result of a reaction: the server's counts.
typedef ReactResult = ({
  int meTooCount,
  bool voted,
  Map<Reaction, int> reactions,
  Reaction? myReaction,
});

/// Campus API (docs/CAMPUS_VOICE.md §4, docs/CAMPUS_SOCIAL.md §3). Every
/// call throws a `Failure`; codes the app shows are mapped in the voice
/// feature.
abstract interface class VoiceRepository {
  /// The university's feed. [kinds] null = every kind. [private] lists
  /// safety issues (officials only).
  Future<VoicePage<IssueCard>> feed({
    IssueSort sort = IssueSort.trending,
    Set<PostKind>? kinds,
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

  /// React with [reaction] (issues: Me too, whatever is passed), or take
  /// the caller's reaction back (null).
  Future<ReactResult> react(String id, Reaction? reaction);

  /// Vote in a poll (once): the poll with its results.
  Future<Poll> votePoll(String id, String optionId);

  Future<bool> follow(String id, {required bool on});

  /// The author reopens a solved issue.
  Future<Issue> reopen(String id, String note);

  Future<VoicePage<IssueComment>> comments(String issueId, {String? cursor});

  /// A comment, or a reply when [parentId] is set.
  Future<IssueComment> addComment(
    String issueId,
    String body, {
    bool anonymous = true,
    String? parentId,
  });

  /// Like on/off: the new count.
  Future<({int likeCount, bool liked})> likeComment(
    String issueId,
    String commentId, {
    required bool on,
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

  /// The caller's own posts of every kind and state, newest first.
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
