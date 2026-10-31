import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';

import '../api_client.dart';

/// Feedback over HTTP (docs/FEEDBACK.md §2).
class ApiFeedbackRepository implements FeedbackRepository {
  ApiFeedbackRepository(this._api);

  final ApiClient _api;

  static Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

  static String _seg(String v) => Uri.encodeComponent(v);

  @override
  Future<FeedbackEntry> send(FeedbackDraft draft) async =>
      FeedbackEntry.fromJson(
        _map(await _api.post('/feedback', draft.toJson())),
      );

  @override
  Future<List<FeedbackEntry>> mine() async {
    final data = _map(await _api.get('/me/feedback'));
    return [
      for (final i in data['items'] as List<Object?>? ?? const [])
        FeedbackEntry.fromJson(_map(i)),
    ];
  }

  @override
  Future<FeedbackThread> thread(String id) async {
    final data = _map(await _api.get('/feedback/${_seg(id)}'));
    return FeedbackThread(FeedbackEntry.fromJson(_map(data['feedback'])), [
      for (final m in data['messages'] as List<Object?>? ?? const [])
        FeedbackMessage.fromJson(_map(m)),
    ]);
  }

  @override
  Future<FeedbackMessage> reply(String id, String body) async =>
      FeedbackMessage.fromJson(
        _map(
          await _api.post('/feedback/${_seg(id)}/messages', {
            'body': body.trim(),
          }),
        ),
      );

  @override
  Future<String> upload(
    Uint8List bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final data = _map(
      await _api.postMultipart(
        '/uploads',
        field: 'image',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      ),
    );
    return data['id']! as String;
  }

  @override
  Future<Uint8List> image(String url) {
    // The API sends a full URL or a path: the client adds the base itself.
    final at = url.indexOf('/api/v1');
    final path = at >= 0 ? url.substring(at + '/api/v1'.length) : url;
    return _api.getBytes(path);
  }
}
