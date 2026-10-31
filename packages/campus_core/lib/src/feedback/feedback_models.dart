import 'dart:typed_data';

DateTime? _time(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

enum FeedbackKind {
  bug,
  idea,
  other;

  static FeedbackKind parse(Object? v) =>
      FeedbackKind.values.firstWhere((k) => k.name == v, orElse: () => other);
}

enum FeedbackStatus {
  fresh('new'),
  seen('seen'),
  planned('planned'),
  inProgress('in_progress'),
  done('done'),
  wontDo('wont_do');

  const FeedbackStatus(this.wire);

  final String wire;

  static FeedbackStatus parse(Object? v) =>
      FeedbackStatus.values.firstWhere((s) => s.wire == v, orElse: () => fresh);

  bool get closed => this == done || this == wontDo;
}

class FeedbackImage {
  const FeedbackImage({required this.url, required this.thumbUrl});

  factory FeedbackImage.fromJson(Map<String, Object?> json) => FeedbackImage(
    url: json['url'] as String? ?? '',
    thumbUrl: json['thumbUrl'] as String? ?? json['url'] as String? ?? '',
  );

  final String url;
  final String thumbUrl;
}

/// A piece of feedback the student sent.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.kind,
    required this.message,
    required this.status,
    this.images = const [],
    this.createdAt,
    this.lastMessageAt,
    this.unread = false,
  });

  factory FeedbackEntry.fromJson(Map<String, Object?> json) => FeedbackEntry(
    id: json['id']! as String,
    kind: FeedbackKind.parse(json['kind']),
    message: json['message'] as String? ?? '',
    status: FeedbackStatus.parse(json['status']),
    images: [
      for (final i in json['images'] as List<Object?>? ?? const [])
        if (i is Map<String, Object?>) FeedbackImage.fromJson(i),
    ],
    createdAt: _time(json['createdAt']),
    lastMessageAt: _time(json['lastMessageAt']),
    unread: switch (json['unread']) {
      final bool b => b,
      final num n => n > 0,
      _ => false,
    },
  );

  final String id;
  final FeedbackKind kind;
  final String message;
  final FeedbackStatus status;
  final List<FeedbackImage> images;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
  final bool unread;

  FeedbackEntry copyWith({FeedbackStatus? status, bool? unread}) =>
      FeedbackEntry(
        id: id,
        kind: kind,
        message: message,
        status: status ?? this.status,
        images: images,
        createdAt: createdAt,
        lastMessageAt: lastMessageAt,
        unread: unread ?? this.unread,
      );
}

class FeedbackMessage {
  const FeedbackMessage({
    required this.id,
    required this.fromTeam,
    required this.body,
    this.createdAt,
  });

  factory FeedbackMessage.fromJson(Map<String, Object?> json) =>
      FeedbackMessage(
        id: json['id'] as String? ?? '',
        fromTeam: json['fromTeam'] as bool? ?? false,
        body: json['body'] as String? ?? '',
        createdAt: _time(json['createdAt']),
      );

  final String id;
  final bool fromTeam;
  final String body;
  final DateTime? createdAt;
}

class FeedbackThread {
  const FeedbackThread(this.feedback, this.messages);

  final FeedbackEntry feedback;
  final List<FeedbackMessage> messages;
}

/// What the app sends along with a report.
class FeedbackDraft {
  const FeedbackDraft({
    required this.kind,
    required this.message,
    this.imageIds = const [],
    this.appVersion = '',
    this.build = 0,
    this.platform = 'android',
    this.device = '',
    this.os = '',
    this.locale = '',
  });

  static const minLength = 10;
  static const maxLength = 2000;
  static const maxImages = 3;

  final FeedbackKind kind;
  final String message;
  final List<String> imageIds;
  final String appVersion;
  final int build;
  final String platform;
  final String device;
  final String os;
  final String locale;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'message': message.trim(),
    if (imageIds.isNotEmpty) 'images': imageIds,
    'appVersion': appVersion,
    'build': build,
    'platform': platform,
    'device': device,
    'os': os,
    'locale': locale,
  };
}

/// Feedback API (docs/FEEDBACK.md §2). Every call throws a `Failure`
/// (`FEEDBACK_LIMIT`, `FEEDBACK_NOT_FOUND`, ...).
abstract interface class FeedbackRepository {
  Future<FeedbackEntry> send(FeedbackDraft draft);

  /// The caller's feedback, newest activity first.
  Future<List<FeedbackEntry>> mine();

  /// Opening it clears its unread mark.
  Future<FeedbackThread> thread(String id);

  Future<FeedbackMessage> reply(String id, String body);

  /// A screenshot (already made smaller on the phone); returns its upload id.
  Future<String> upload(
    Uint8List bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  });

  /// An attached screenshot, by its url from the API.
  Future<Uint8List> image(String url);
}
