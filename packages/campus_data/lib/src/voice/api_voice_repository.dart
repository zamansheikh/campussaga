import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Campus Voice over HTTP (docs/CAMPUS_VOICE.md §4.2–4.3).
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

  @override
  Future<VoicePage<IssueCard>> feed({
    IssueSort sort = IssueSort.trending,
    IssueCategory? category,
    String? query,
    String? cursor,
    bool private = false,
  }) async => _page(
    await _api.get(
      '/issues${_q({'sort': sort.wire, 'category': category?.wire, 'q': query?.trim(), 'cursor': cursor, 'private': private ? 'true' : null})}',
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
  Future<({int meTooCount, bool voted})> vote(
    String id, {
    required bool on,
  }) async {
    final data = _map(
      on
          ? await _api.put('/issues/$id/vote', null)
          : await _api.delete('/issues/$id/vote'),
    );
    return (
      meTooCount: (data['meTooCount'] as num?)?.toInt() ?? 0,
      voted: data['voted'] as bool? ?? on,
    );
  }

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
  }) async => IssueComment.fromJson(
    _map(
      await _api.post('/issues/$issueId/comments', {
        'body': body.trim(),
        'anonymous': anonymous,
      }),
    ),
  );

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
    await _api.get('/me/issues${_q({'cursor': cursor})}'),
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
