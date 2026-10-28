// Campus Voice (docs/CAMPUS_VOICE.md §4.1): campus issues, anonymous by
// default. Nothing here ever carries who wrote anonymous content: the
// server only says whether it is the caller's own ([IssueCard.mine]).

/// What an issue is about. Unknown values from a newer server → [other].
enum IssueCategory {
  academic,
  hostel,
  transport,
  facilities,
  safety,
  administration,
  food,
  it,
  other;

  String get wire => name;

  /// Safety issues are private: only the author, moderators and the
  /// university's officials see them.
  bool get isPrivate => this == safety;

  static IssueCategory parse(String? v) =>
      values.firstWhere((c) => c.name == v, orElse: () => other);
}

/// Open → Acknowledged → In progress → Solved / Rejected.
enum IssueStatus {
  open('open'),
  acknowledged('acknowledged'),
  inProgress('in_progress'),
  solved('solved'),
  rejected('rejected');

  const IssueStatus(this.wire);

  final String wire;

  bool get isClosed => this == solved || this == rejected;

  /// Where an authority can move an issue from here (§4.3).
  List<IssueStatus> get next => switch (this) {
    open => const [acknowledged, inProgress, solved, rejected],
    acknowledged => const [inProgress, solved, rejected],
    inProgress => const [solved, rejected],
    solved || rejected => const [],
  };

  static IssueStatus parse(String? v) =>
      values.firstWhere((s) => s.wire == v, orElse: () => open);
}

/// Who can see a post: everyone, or (held/hidden/removed) only its author
/// and staff.
enum ContentVisibility {
  visible,
  held,
  hidden,
  removed;

  static ContentVisibility parse(String? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => visible);
}

/// Feed order.
enum IssueSort {
  trending,
  newest('new'),
  solved;

  const IssueSort([this._wire]);

  final String? _wire;

  String get wire => _wire ?? name;
}

/// Why something is reported.
enum ReportReason {
  spam,
  abuse,
  personalInfo('personal_info'),
  falseInfo('false_info'),
  inappropriate,
  other;

  const ReportReason([this._wire]);

  final String? _wire;

  String get wire => _wire ?? name;
}

/// A name shown on content: named posts and official replies only.
class PostAuthor {
  const PostAuthor({required this.name, this.verified = false});

  factory PostAuthor.fromJson(Map<String, Object?> json) => PostAuthor(
    name: json['name'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
  );

  final String name;
  final bool verified;

  Map<String, Object?> toJson() => {'name': name, 'verified': verified};
}

DateTime _time(Object? v) =>
    DateTime.tryParse(v as String? ?? '')?.toLocal() ??
    DateTime.fromMillisecondsSinceEpoch(0);

/// An issue in a list (feed, similar issues, my issues).
class IssueCard {
  const IssueCard({
    required this.id,
    required this.category,
    required this.title,
    required this.status,
    required this.createdAt,
    this.private = false,
    this.preview = '',
    this.visibility = ContentVisibility.visible,
    this.meTooCount = 0,
    this.commentCount = 0,
    this.imageCount = 0,
    this.thumbnail,
    this.voted = false,
    this.following = false,
    this.mine = false,
    this.author,
    this.locationLabel = '',
    DateTime? statusChangedAt,
  }) : statusChangedAt = statusChangedAt ?? createdAt;

  factory IssueCard.fromJson(Map<String, Object?> json) => IssueCard(
    id: json['id']! as String,
    category: IssueCategory.parse(json['category'] as String?),
    private: json['private'] as bool? ?? false,
    title: json['title'] as String? ?? '',
    preview: json['preview'] as String? ?? '',
    status: IssueStatus.parse(json['status'] as String?),
    visibility: ContentVisibility.parse(json['visibility'] as String?),
    meTooCount: (json['meTooCount'] as num?)?.toInt() ?? 0,
    commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
    thumbnail: json['thumbnail'] as String?,
    voted: json['voted'] as bool? ?? false,
    following: json['following'] as bool? ?? false,
    mine: json['mine'] as bool? ?? false,
    author: json['author'] is Map<String, Object?>
        ? PostAuthor.fromJson(json['author']! as Map<String, Object?>)
        : null,
    locationLabel: json['locationLabel'] as String? ?? '',
    createdAt: _time(json['createdAt']),
    statusChangedAt: json['statusChangedAt'] == null
        ? null
        : _time(json['statusChangedAt']),
  );

  final String id;
  final IssueCategory category;
  final bool private;
  final String title;

  /// The first lines of the details.
  final String preview;
  final IssueStatus status;

  /// Not [ContentVisibility.visible] only for the author's own and staff.
  final ContentVisibility visibility;
  final int meTooCount;
  final int commentCount;
  final int imageCount;

  /// Image id of the first photo, if any.
  final String? thumbnail;
  final bool voted;
  final bool following;

  /// Posted by the caller (never says who, for anyone else).
  final bool mine;

  /// Set only on posts made with a name.
  final PostAuthor? author;
  final String locationLabel;

  /// Rounded to 5 minutes for anonymous posts (by the server).
  final DateTime createdAt;
  final DateTime statusChangedAt;

  bool get anonymous => author == null;

  IssueCard copyWith({
    bool? voted,
    int? meTooCount,
    bool? following,
    int? commentCount,
    IssueStatus? status,
  }) => IssueCard(
    id: id,
    category: category,
    private: private,
    title: title,
    preview: preview,
    status: status ?? this.status,
    visibility: visibility,
    meTooCount: meTooCount ?? this.meTooCount,
    commentCount: commentCount ?? this.commentCount,
    imageCount: imageCount,
    thumbnail: thumbnail,
    voted: voted ?? this.voted,
    following: following ?? this.following,
    mine: mine,
    author: author,
    locationLabel: locationLabel,
    createdAt: createdAt,
    statusChangedAt: statusChangedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.wire,
    'private': private,
    'title': title,
    'preview': preview,
    'status': status.wire,
    'visibility': visibility.name,
    'meTooCount': meTooCount,
    'commentCount': commentCount,
    'imageCount': imageCount,
    'thumbnail': thumbnail,
    'voted': voted,
    'following': following,
    'mine': mine,
    'author': author?.toJson(),
    'locationLabel': locationLabel,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'statusChangedAt': statusChangedAt.toUtc().toIso8601String(),
  };
}

/// A photo of an issue.
class IssueImage {
  const IssueImage({required this.id, this.width = 0, this.height = 0});

  factory IssueImage.fromJson(Map<String, Object?> json) => IssueImage(
    id: json['id']! as String,
    width: (json['width'] as num?)?.toInt() ?? 0,
    height: (json['height'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final int width;
  final int height;

  double get aspect => width > 0 && height > 0 ? width / height : 4 / 3;

  Map<String, Object?> toJson() => {'id': id, 'width': width, 'height': height};
}

/// Who changed a status.
enum TimelineActor {
  authority,
  moderator,
  author,
  system;

  static TimelineActor parse(String? v) =>
      values.firstWhere((a) => a.name == v, orElse: () => system);
}

/// One step of an issue's status history.
class TimelineEntry {
  const TimelineEntry({
    required this.from,
    required this.to,
    required this.actor,
    required this.createdAt,
    this.actorTitle = '',
    this.note = '',
  });

  factory TimelineEntry.fromJson(Map<String, Object?> json) => TimelineEntry(
    from: IssueStatus.parse(json['from'] as String?),
    to: IssueStatus.parse(json['to'] as String?),
    actor: TimelineActor.parse(json['actorKind'] as String?),
    actorTitle: json['actorTitle'] as String? ?? '',
    note: json['note'] as String? ?? '',
    createdAt: _time(json['createdAt']),
  );

  final IssueStatus from;
  final IssueStatus to;
  final TimelineActor actor;

  /// The official's public title ("Proctor Office").
  final String actorTitle;
  final String note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'from': from.wire,
    'to': to.wire,
    'actorKind': actor.name,
    'actorTitle': actorTitle,
    'note': note,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// What the caller may do with an issue (computed by the server).
class IssueCan {
  const IssueCan({
    this.edit = false,
    this.delete = false,
    this.reopen = false,
    this.changeStatus = false,
    this.officialReply = false,
    this.moderate = false,
  });

  factory IssueCan.fromJson(Map<String, Object?>? json) => json == null
      ? const IssueCan()
      : IssueCan(
          edit: json['edit'] as bool? ?? false,
          delete: json['delete'] as bool? ?? false,
          reopen: json['reopen'] as bool? ?? false,
          changeStatus: json['changeStatus'] as bool? ?? false,
          officialReply: json['officialReply'] as bool? ?? false,
          moderate: json['moderate'] as bool? ?? false,
        );

  final bool edit;
  final bool delete;
  final bool reopen;
  final bool changeStatus;
  final bool officialReply;
  final bool moderate;

  Map<String, Object?> toJson() => {
    'edit': edit,
    'delete': delete,
    'reopen': reopen,
    'changeStatus': changeStatus,
    'officialReply': officialReply,
    'moderate': moderate,
  };
}

/// An issue opened in full.
class Issue {
  const Issue({
    required this.card,
    this.body = '',
    this.images = const [],
    this.timeline = const [],
    this.holdReason = '',
    this.removedReason = '',
    this.can = const IssueCan(),
  });

  factory Issue.fromJson(Map<String, Object?> json) => Issue(
    card: IssueCard.fromJson(json),
    body: json['body'] as String? ?? '',
    images: [
      for (final i in json['images'] as List<Object?>? ?? const [])
        if (i is Map<String, Object?>) IssueImage.fromJson(i),
    ],
    timeline: [
      for (final t in json['timeline'] as List<Object?>? ?? const [])
        if (t is Map<String, Object?>) TimelineEntry.fromJson(t),
    ],
    holdReason: json['holdReason'] as String? ?? '',
    removedReason: json['removedReason'] as String? ?? '',
    can: IssueCan.fromJson(json['can'] as Map<String, Object?>?),
  );

  final IssueCard card;
  final String body;
  final List<IssueImage> images;
  final List<TimelineEntry> timeline;

  /// Why it is held for review (only the author sees it).
  final String holdReason;

  /// Why a moderator removed it (only the author sees it).
  final String removedReason;
  final IssueCan can;

  String get id => card.id;

  Issue withCard(IssueCard c) => Issue(
    card: c,
    body: body,
    images: images,
    timeline: timeline,
    holdReason: holdReason,
    removedReason: removedReason,
    can: can,
  );

  Map<String, Object?> toJson() => {
    ...card.toJson(),
    'body': body,
    'images': [for (final i in images) i.toJson()],
    'timeline': [for (final t in timeline) t.toJson()],
    'holdReason': holdReason,
    'removedReason': removedReason,
    'can': can.toJson(),
  };
}

enum CommentKind {
  student,
  official;

  static CommentKind parse(String? v) => v == 'official' ? official : student;
}

/// A comment. Anonymous students appear by a per-issue handle
/// ("Student 7KQF"); the issue's own author as "Author".
class IssueComment {
  const IssueComment({
    required this.id,
    required this.body,
    required this.createdAt,
    this.kind = CommentKind.student,
    this.handle = '',
    this.isIssueAuthor = false,
    this.mine = false,
    this.author,
    this.officialTitle = '',
    this.visibility = ContentVisibility.visible,
    this.removedReason = '',
  });

  factory IssueComment.fromJson(Map<String, Object?> json) => IssueComment(
    id: json['id']! as String,
    kind: CommentKind.parse(json['kind'] as String?),
    handle: json['handle'] as String? ?? '',
    isIssueAuthor: json['isIssueAuthor'] as bool? ?? false,
    mine: json['mine'] as bool? ?? false,
    author: json['author'] is Map<String, Object?>
        ? PostAuthor.fromJson(json['author']! as Map<String, Object?>)
        : null,
    officialTitle: json['officialTitle'] as String? ?? '',
    body: json['body'] as String? ?? '',
    visibility: ContentVisibility.parse(json['visibility'] as String?),
    removedReason: json['removedReason'] as String? ?? '',
    createdAt: _time(json['createdAt']),
  );

  final String id;
  final CommentKind kind;
  final String handle;
  final bool isIssueAuthor;
  final bool mine;
  final PostAuthor? author;
  final String officialTitle;
  final String body;
  final ContentVisibility visibility;
  final String removedReason;
  final DateTime createdAt;

  bool get official => kind == CommentKind.official;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'handle': handle,
    'isIssueAuthor': isIssueAuthor,
    'mine': mine,
    'author': author?.toJson(),
    'officialTitle': officialTitle,
    'body': body,
    'visibility': visibility.name,
    'removedReason': removedReason,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// One page of a list; [nextCursor] null = the end.
class VoicePage<T> {
  const VoicePage(this.items, [this.nextCursor]);

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// A photo uploaded but not yet attached to an issue.
class VoiceUpload {
  const VoiceUpload({required this.id, this.width = 0, this.height = 0});

  factory VoiceUpload.fromJson(Map<String, Object?> json) => VoiceUpload(
    id: json['id']! as String,
    width: (json['width'] as num?)?.toInt() ?? 0,
    height: (json['height'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final int width;
  final int height;
}

/// A new issue.
class IssueDraft {
  const IssueDraft({
    required this.category,
    required this.title,
    required this.body,
    this.locationLabel = '',
    this.anonymous = true,
    this.imageIds = const [],
  });

  final IssueCategory category;
  final String title;
  final String body;
  final String locationLabel;
  final bool anonymous;
  final List<String> imageIds;

  static const minTitle = 8;
  static const maxTitle = 120;
  static const minBody = 20;
  static const maxBody = 3000;
  static const maxLocation = 80;
  static const maxPhotos = 4;

  Map<String, Object?> toJson() => {
    'category': category.wire,
    'title': title.trim(),
    'body': body.trim(),
    'locationLabel': locationLabel.trim(),
    'anonymous': anonymous,
    'imageIds': imageIds,
  };
}
