import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Campus over HTTP (docs/CAMPUS_VOICE.md §4.2–4.3, docs/CAMPUS_SOCIAL.md §3).
class ApiVoiceRepository implements VoiceRepository {
  ApiVoiceRepository(this._api);

  final ApiClient _api;

  static String _q(Map<String, String?> params) {
    final p = {
      for (final e in params.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return p.isEmpty ? '' : '?${Uri(queryParameters: p).query}';
  }

  static Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

  static VoicePage<T> _page<T>(
    Object? data,
    T Function(Map<String, Object?>) item,
  ) {
    final json = _map(data);
    return VoicePage([
      for (final i in json['items'] as List<Object?>? ?? const [])
        item(_map(i)),
    ], json['nextCursor'] as String?);
  }

  /// The `kinds` query value: every kind unless narrowed.
  static String _kinds(Set<PostKind>? kinds) =>
      kinds == null || kinds.length == PostKind.values.length
      ? 'all'
      : [
          for (final k in PostKind.values)
            if (kinds.contains(k)) k.wire,
        ].join(',');

  @override
  Future<VoicePage<IssueCard>> feed({
    IssueSort sort = IssueSort.trending,
    Set<PostKind>? kinds,
    IssueCategory? category,
    String? query,
    String? cursor,
    bool private = false,
  }) async => _page(
    await _api.get(
      '/issues${_q({'sort': sort.wire, 'kinds': _kinds(kinds), 'category': category?.wire, 'q': query?.trim(), 'cursor': cursor, 'private': private ? 'true' : null})}',
    ),
    IssueCard.fromJson,
  );

  @override
  Future<List<IssueCard>> similar(String title) async {
    final data = _map(
      await _api.get('/issues/similar${_q({'q': title.trim()})}'),
    );
    return [
      for (final i in data['items'] as List<Object?>? ?? const [])
        IssueCard.fromJson(_map(i)),
    ];
  }

  @override
  Future<Issue> issue(String id) async =>
      Issue.fromJson(_map(await _api.get('/issues/$id')));

  @override
  Future<Issue> create(IssueDraft draft) async =>
      Issue.fromJson(_map(await _api.post('/issues', draft.toJson())));

  @override
  Future<Issue> edit(
    String id, {
    String? title,
    String? body,
    String? locationLabel,
  }) async => Issue.fromJson(
    _map(
      await _api.patch('/issues/$id', {
        'title': ?title?.trim(),
        'body': ?body?.trim(),
        'locationLabel': ?locationLabel?.trim(),
      }),
    ),
  );

  @override
  Future<void> delete(String id) => _api.delete('/issues/$id');

  @override
  Future<ReactResult> react(String id, Reaction? reaction) async {
    final data = _map(
      reaction != null
          ? await _api.put('/issues/$id/vote', {'reaction': reaction.wire})
          : await _api.delete('/issues/$id/vote'),
    );
    final counts = <Reaction, int>{};
    if (data['reactions'] case final Map<String, Object?> m) {
      for (final e in m.entries) {
        final r = Reaction.parse(e.key);
        final n = (e.value as num?)?.toInt() ?? 0;
        if (r != null && n > 0) counts[r] = n;
      }
    }
    return (
      meTooCount: (data['meTooCount'] as num?)?.toInt() ?? 0,
      voted: data['voted'] as bool? ?? reaction != null,
      reactions: counts,
      myReaction: Reaction.parse(data['myReaction'] as String?),
    );
  }

  @override
  Future<Poll> votePoll(String id, String optionId) async => Poll.fromJson(
    _map(await _api.post('/issues/$id/poll-vote', {'optionId': optionId})),
  );

  @override
  Future<bool> follow(String id, {required bool on}) async {
    final data = on
        ? await _api.put('/issues/$id/follow', null)
        : await _api.delete('/issues/$id/follow');
    return data is Map<String, Object?> ? data['following'] as bool? ?? on : on;
  }

  @override
  Future<Issue> reopen(String id, String note) async => Issue.fromJson(
    _map(await _api.post('/issues/$id/reopen', {'note': note.trim()})),
  );

  @override
  Future<VoicePage<IssueComment>> comments(
    String issueId, {
    String? cursor,
  }) async => _page(
    await _api.get('/issues/$issueId/comments${_q({'cursor': cursor})}'),
    IssueComment.fromJson,
  );

  @override
  Future<IssueComment> addComment(
    String issueId,
    String body, {
    bool anonymous = true,
    String? parentId,
  }) async => IssueComment.fromJson(
    _map(
      await _api.post('/issues/$issueId/comments', {
        'body': body.trim(),
        'anonymous': anonymous,
        'parentId': ?parentId,
      }),
    ),
  );

  @override
  Future<({int likeCount, bool liked})> likeComment(
    String issueId,
    String commentId, {
    required bool on,
  }) async {
    final path = '/issues/$issueId/comments/$commentId/like';
    final data = _map(
      on ? await _api.put(path, null) : await _api.delete(path),
    );
    return (
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      liked: data['liked'] as bool? ?? on,
    );
  }

  @override
  Future<void> deleteComment(String issueId, String commentId) =>
      _api.delete('/issues/$issueId/comments/$commentId');

  @override
  Future<void> report(
    String issueId,
    ReportReason reason, {
    String details = '',
  }) => _api.post('/issues/$issueId/report', {
    'reason': reason.wire,
    if (details.trim().isNotEmpty) 'details': details.trim(),
  });

  @override
  Future<void> reportComment(
    String issueId,
    String commentId,
    ReportReason reason, {
    String details = '',
  }) => _api.post('/issues/$issueId/comments/$commentId/report', {
    'reason': reason.wire,
    if (details.trim().isNotEmpty) 'details': details.trim(),
  });

  @override
  Future<VoicePage<IssueCard>> myIssues({String? cursor}) async => _page(
    await _api.get('/me/issues${_q({'kinds': 'all', 'cursor': cursor})}'),
    IssueCard.fromJson,
  );

  @override
  Future<VoiceUpload> upload(
    Uint8List bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async => VoiceUpload.fromJson(
    _map(
      await _api.postMultipart(
        '/uploads',
        field: 'image',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      ),
    ),
  );

  @override
  Future<Uint8List> image(String imageId, {bool thumb = false}) =>
      _api.getBytes('/issues/images/$imageId?size=${thumb ? 'thumb' : 'full'}');

  @override
  Future<Issue> changeStatus(
    String id,
    IssueStatus to, {
    String note = '',
  }) async => Issue.fromJson(
    _map(
      await _api.post('/issues/$id/status', {
        'to': to.wire,
        'note': note.trim(),
      }),
    ),
  );

  @override
  Future<IssueComment> officialReply(String issueId, String body) async =>
      IssueComment.fromJson(
        _map(
          await _api.post('/issues/$issueId/official-replies', {
            'body': body.trim(),
          }),
        ),
      );
}
