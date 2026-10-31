import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:varsitykotha/features/voice/data/photo_picker.dart';

/// A 1×1 PNG, so Image.memory works in tests.
final onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// An issue for tests.
Issue sampleIssue({
  String id = 'i1',
  PostKind kind = PostKind.issue,
  String title = 'No water in Hall 2 since Sunday',
  String body = 'The taps on the 3rd floor are dry since Sunday morning.',
  Poll? poll,
  Map<Reaction, int> reactions = const {},
  Reaction? myReaction,
  IssueCategory category = IssueCategory.hostel,
  IssueStatus status = IssueStatus.open,
  ContentVisibility visibility = ContentVisibility.visible,
  bool mine = false,
  bool voted = false,
  int meToo = 4,
  PostAuthor? author,
  IssueCan can = const IssueCan(),
  String holdReason = '',
  List<IssueImage> images = const [],
  List<TimelineEntry> timeline = const [],
  DateTime? createdAt,
}) => Issue(
  card: IssueCard(
    id: id,
    kind: kind,
    category: category,
    private: category == IssueCategory.safety,
    title: kind == PostKind.issue ? title : '',
    preview: kind == PostKind.issue
        ? 'The taps on the 3rd floor are dry.'
        : body,
    poll: poll,
    reactions: reactions,
    myReaction: myReaction,
    status: status,
    visibility: visibility,
    meTooCount: meToo,
    commentCount: 0,
    imageCount: images.length,
    thumbnail: images.isEmpty ? null : images.first.id,
    voted: voted,
    mine: mine,
    author: author,
    locationLabel: 'Hall 2',
    createdAt: createdAt ?? DateTime(2026, 10, 27, 8),
  ),
  body: body,
  images: images,
  timeline: timeline,
  holdReason: holdReason,
  can: can,
);

/// In-memory Campus Voice.
class FakeVoiceRepository implements VoiceRepository {
  final issues = <Issue>[];
  final commentsByIssue = <String, List<IssueComment>>{};
  final reports = <(String, String?, ReportReason)>[];
  final created = <IssueDraft>[];
  final uploads = <Uint8List>[];
  final statusChanges = <(String, IssueStatus, String)>[];
  final feedCalls =
      <
        ({
          IssueSort sort,
          Set<PostKind>? kinds,
          IssueCategory? category,
          String? query,
          bool private,
        })
      >[];

  /// Every call fails with this (e.g. NetworkFailure: offline).
  Failure? failure;

  /// Only voting fails with this (rollback tests).
  Failure? voteFailure;

  /// New posts come back under review (auto-check).
  bool holdNext = false;
  List<IssueCard> similarResult = const [];
  var _ids = 0;

  void _check() {
    if (failure != null) throw failure!;
  }

  Issue _find(String id) => issues.firstWhere(
    (i) => i.id == id,
    orElse: () => throw const NotFoundFailure(code: 'ISSUE_NOT_FOUND'),
  );

  void _put(Issue issue) {
    final at = issues.indexWhere((i) => i.id == issue.id);
    if (at < 0) {
      issues.insert(0, issue);
    } else {
      issues[at] = issue;
    }
  }

  @override
  Future<VoicePage<IssueCard>> feed({
    IssueSort sort = IssueSort.trending,
    String? universityId,
    Set<PostKind>? kinds,
    IssueCategory? category,
    String? query,
    String? cursor,
    bool private = false,
  }) async {
    feedCalls.add((
      sort: sort,
      kinds: kinds,
      category: category,
      query: query,
      private: private,
    ));
    _check();
    if (universityId != null) {
      lastVisited = universityId;
      return VoicePage([
        for (final c in visitPosts[universityId] ?? const <IssueCard>[])
          if (kinds == null || kinds.contains(c.kind)) c,
      ]);
    }
    final q = query?.toLowerCase() ?? '';
    return VoicePage([
      for (final i in issues)
        if (i.card.visibility == ContentVisibility.visible &&
            (kinds == null || kinds.contains(i.card.kind)) &&
            i.card.private == private &&
            (category == null || i.card.category == category) &&
            (q.isEmpty ||
                '${i.card.title} ${i.card.preview}'.toLowerCase().contains(
                  q,
                )) &&
            (sort != IssueSort.solved || i.card.status == IssueStatus.solved))
          i.card,
    ]);
  }

  @override
  Future<List<IssueCard>> similar(String title) async {
    _check();
    return similarResult;
  }

  @override
  Future<Issue> issue(String id) async {
    _check();
    return _find(id);
  }

  @override
  Future<Issue> create(IssueDraft draft) async {
    _check();
    created.add(draft);
    final issue = sampleIssue(
      id: 'new${++_ids}',
      kind: draft.kind,
      title: draft.title,
      body: draft.body,
      category: draft.category,
      poll: draft.kind != PostKind.poll
          ? null
          : Poll(
              options: [
                for (final (n, o) in draft.pollOptions.indexed)
                  PollOption(id: 'o$n', label: o),
              ],
              closesAt: DateTime(
                2026,
                10,
                27,
                8,
              ).add(Duration(days: draft.pollDays)),
            ),
      mine: true,
      meToo: 0,
      visibility: holdNext ? ContentVisibility.held : ContentVisibility.visible,
      holdReason: holdNext ? 'personal_info' : '',
      author: draft.anonymous
          ? null
          : const PostAuthor(name: 'Rafi', verified: true),
      can: const IssueCan(edit: true, delete: true),
      images: [for (final id in draft.imageIds) IssueImage(id: id)],
    );
    _put(issue);
    return issue;
  }

  @override
  Future<Issue> edit(
    String id, {
    String? title,
    String? body,
    String? locationLabel,
  }) async {
    _check();
    final i = _find(id);
    final next = sampleIssue(
      id: id,
      title: title ?? i.card.title,
      mine: i.card.mine,
      can: i.can,
    );
    _put(next);
    return next;
  }

  @override
  Future<void> delete(String id) async {
    _check();
    issues.removeWhere((i) => i.id == id);
  }

  @override
  Future<ReactResult> react(String id, Reaction? reaction) async {
    _check();
    if (voteFailure != null) throw voteFailure!;
    final i = _find(id);
    if (i.card.isIssue && i.card.mine && reaction != null) {
      throw const RejectedFailure(code: 'CANNOT_VOTE_OWN');
    }
    final r = i.card.isIssue && reaction != null ? Reaction.meToo : reaction;
    final next = i.card.reacted(r);
    _put(i.withCard(next));
    return (
      meTooCount: next.meTooCount,
      voted: next.voted,
      reactions: next.reactions,
      myReaction: next.myReaction,
    );
  }

  @override
  Future<Poll> votePoll(String id, String optionId) async {
    _check();
    final i = _find(id);
    final poll = i.card.poll;
    if (poll == null) throw const RejectedFailure(code: 'POLL_CLOSED');
    if (poll.myVote != null) {
      throw const RejectedFailure(code: 'ALREADY_VOTED');
    }
    final next = Poll(
      options: [
        for (final o in poll.options)
          PollOption(
            id: o.id,
            label: o.label,
            votes: (o.votes ?? 0) + (o.id == optionId ? 1 : 0),
          ),
      ],
      totalVotes: poll.totalVotes + 1,
      myVote: optionId,
      closesAt: poll.closesAt,
    );
    _put(i.withCard(i.card.copyWith(poll: next)));
    return next;
  }

  @override
  Future<bool> follow(String id, {required bool on}) async {
    _check();
    final i = _find(id);
    _put(i.withCard(i.card.copyWith(following: on)));
    return on;
  }

  @override
  Future<Issue> reopen(String id, String note) async {
    _check();
    final i = _find(id);
    final next = i.withCard(i.card.copyWith(status: IssueStatus.open));
    _put(next);
    return next;
  }

  @override
  Future<VoicePage<IssueComment>> comments(
    String issueId, {
    String? cursor,
  }) async {
    _check();
    return VoicePage([...?commentsByIssue[issueId]]);
  }

  @override
  Future<IssueComment> addComment(
    String issueId,
    String body, {
    bool anonymous = true,
    String? parentId,
  }) async {
    _check();
    final c = IssueComment(
      id: 'c${++_ids}',
      parentId: parentId,
      body: body,
      handle: anonymous ? '7KQF' : '',
      mine: true,
      author: anonymous ? null : const PostAuthor(name: 'Rafi'),
      createdAt: DateTime(2026, 10, 27, 9),
    );
    (commentsByIssue[issueId] ??= []).add(c);
    return c;
  }

  @override
  Future<({int likeCount, bool liked})> likeComment(
    String issueId,
    String commentId, {
    required bool on,
  }) async {
    _check();
    final list = commentsByIssue[issueId] ?? [];
    final at = list.indexWhere((c) => c.id == commentId);
    if (at < 0) throw const NotFoundFailure(code: 'COMMENT_NOT_FOUND');
    final c = list[at];
    final n = c.likeCount + (on == c.liked ? 0 : (on ? 1 : -1));
    list[at] = c.copyWith(likeCount: n, liked: on);
    return (likeCount: n, liked: on);
  }

  @override
  Future<void> deleteComment(String issueId, String commentId) async {
    _check();
    commentsByIssue[issueId]?.removeWhere((c) => c.id == commentId);
  }

  @override
  Future<void> report(
    String issueId,
    ReportReason reason, {
    String details = '',
  }) async {
    _check();
    reports.add((issueId, null, reason));
  }

  @override
  Future<void> reportComment(
    String issueId,
    String commentId,
    ReportReason reason, {
    String details = '',
  }) async {
    _check();
    reports.add((issueId, commentId, reason));
  }

  @override
  Future<VoicePage<IssueCard>> myIssues({String? cursor}) async {
    _check();
    return VoicePage([
      for (final i in issues)
        if (i.card.mine) i.card,
    ]);
  }

  @override
  Future<VoiceUpload> upload(
    Uint8List bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    _check();
    uploads.add(bytes);
    return VoiceUpload(id: 'up${uploads.length}', width: 1, height: 1);
  }

  @override
  Future<Uint8List> image(String imageId, {bool thumb = false}) async =>
      onePixelPng;

  /// Other universities, and the posts each one shows a visitor.
  final campusList = <CampusSummary>[];
  final campusProfiles = <String, CampusProfile>{};
  final visitPosts = <String, List<IssueCard>>{};
  String? lastVisited;

  @override
  Future<VoicePage<CampusSummary>> campuses({
    String? query,
    String? cursor,
  }) async {
    _check();
    final q = query?.trim().toLowerCase() ?? '';
    return VoicePage([
      for (final c in campusList)
        if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ]);
  }

  @override
  Future<CampusProfile> campus(String slug) async {
    _check();
    return campusProfiles[slug] ??
        (throw const NotFoundFailure(code: 'UNIVERSITY_NOT_FOUND'));
  }

  @override
  Future<Issue> changeStatus(
    String id,
    IssueStatus to, {
    String note = '',
  }) async {
    _check();
    statusChanges.add((id, to, note));
    final i = _find(id);
    final next = Issue(
      card: i.card.copyWith(status: to),
      body: i.body,
      timeline: [
        ...i.timeline,
        TimelineEntry(
          from: i.card.status,
          to: to,
          actor: TimelineActor.authority,
          actorTitle: 'Hall Provost',
          note: note,
          createdAt: DateTime(2026, 10, 27, 10),
        ),
      ],
      can: i.can,
    );
    _put(next);
    return next;
  }

  @override
  Future<IssueComment> officialReply(String issueId, String body) async {
    _check();
    final c = IssueComment(
      id: 'o${++_ids}',
      kind: CommentKind.official,
      body: body,
      officialTitle: 'Hall Provost',
      author: const PostAuthor(name: 'Dr. Karim', verified: true),
      createdAt: DateTime(2026, 10, 27, 10),
    );
    (commentsByIssue[issueId] ??= []).add(c);
    return c;
  }
}

/// Returns [next] (null = cancelled).
class FakePhotoPicker implements PhotoPicker {
  PickedPhoto? next = PickedPhoto(bytes: onePixelPng);
  int picks = 0;

  @override
  Future<PickedPhoto?> pick({required bool camera}) async {
    picks++;
    return next;
  }

  @override
  Future<PickedPhoto?> pickSquare({
    required bool camera,
    required String title,
    required Color color,
  }) async {
    picks++;
    return next;
  }
}
