import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:campussaga/features/voice/data/photo_picker.dart';

/// A 1×1 PNG, so Image.memory works in tests.
final onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// An issue for tests.
Issue sampleIssue({
  String id = 'i1',
  String title = 'No water in Hall 2 since Sunday',
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
    category: category,
    private: category == IssueCategory.safety,
    title: title,
    preview: 'The taps on the 3rd floor are dry.',
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
  body: 'The taps on the 3rd floor are dry since Sunday morning.',
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
        ({IssueSort sort, IssueCategory? category, String? query, bool private})
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
    IssueCategory? category,
    String? query,
    String? cursor,
    bool private = false,
  }) async {
    feedCalls.add((
      sort: sort,
      category: category,
      query: query,
      private: private,
    ));
    _check();
    final q = query?.toLowerCase() ?? '';
    return VoicePage([
      for (final i in issues)
        if (i.card.visibility == ContentVisibility.visible &&
            i.card.private == private &&
            (category == null || i.card.category == category) &&
            (q.isEmpty || i.card.title.toLowerCase().contains(q)) &&
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
      title: draft.title,
      category: draft.category,
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
  Future<({int meTooCount, bool voted})> vote(
    String id, {
    required bool on,
  }) async {
    _check();
    if (voteFailure != null) throw voteFailure!;
    final i = _find(id);
    final count = i.card.meTooCount + (on == i.card.voted ? 0 : (on ? 1 : -1));
    _put(i.withCard(i.card.copyWith(voted: on, meTooCount: count)));
    return (meTooCount: count, voted: on);
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
  }) async {
    _check();
    final c = IssueComment(
      id: 'c${++_ids}',
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
}
