// Campus Voice (docs/CAMPUS_VOICE.md §4.1): campus issues, anonymous by
// default. Nothing here ever carries who wrote anonymous content: the
// server only says whether it is the caller's own ([IssueCard.mine]).

/// What a post is about. Issues use the first nine; posts, questions and
/// polls use every one but [safety] (docs/CAMPUS_SOCIAL.md §1). Unknown
/// values from a newer server → [other].
enum IssueCategory {
  academic,
  hostel,
  transport,
  facilities,
  safety,
  administration,
  food,
  it,
  other,
  general,
  event,
  lostFound('lost_found'),
  buySell('buy_sell'),
  fun;

  const IssueCategory([this._wire]);

  final String? _wire;

  String get wire => _wire ?? name;

  /// Safety issues are private: only the author, moderators and the
  /// university's officials see them.
  bool get isPrivate => this == safety;

  /// What an issue can be about.
  static const forIssues = [
    academic,
    hostel,
    transport,
    facilities,
    safety,
    administration,
    food,
    it,
    other,
  ];

  /// Topics of posts, questions and polls, most used first.
  static const forPosts = [
    general,
    event,
    lostFound,
    buySell,
    fun,
    academic,
    hostel,
    transport,
    food,
    it,
    facilities,
    administration,
    other,
  ];

  static IssueCategory parse(String? v) =>
      values.firstWhere((c) => c.wire == v, orElse: () => other);
}

/// The kinds of post on Campus. Unknown values from a newer server → [post].
enum PostKind {
  issue,
  post,
  question,
  poll;

  String get wire => name;

  static PostKind parse(String? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => post);
}

/// A reaction. Issues only take [meToo]; the others are for posts,
/// questions and polls (a tap is [like]).
enum Reaction {
  meToo('me_too', '✋'),
  like('like', '❤️'),
  haha('haha', '😂'),
  wow('wow', '😮'),
  sad('sad', '😢'),
  clap('clap', '👏');

  const Reaction(this.wire, this.emoji);

  final String wire;
  final String emoji;

  /// The ones students pick from on posts.
  static const forPosts = [like, haha, wow, sad, clap];

  static Reaction? parse(String? v) {
    for (final r in values) {
      if (r.wire == v) return r;
    }
    return null;
  }
}

/// One answer of a poll. [votes] is null while the results are hidden (the
/// caller hasn't voted, it isn't theirs and it is still open).
class PollOption {
  const PollOption({required this.id, required this.label, this.votes});

  factory PollOption.fromJson(Map<String, Object?> json) => PollOption(
    id: json['id']! as String,
    label: json['label'] as String? ?? '',
    votes: (json['votes'] as num?)?.toInt(),
  );

  final String id;
  final String label;
  final int? votes;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'votes': votes};
}

/// A poll's options and results.
class Poll {
  const Poll({
    required this.options,
    required this.closesAt,
    this.totalVotes = 0,
    this.myVote,
    this.closed = false,
  });

  factory Poll.fromJson(Map<String, Object?> json) => Poll(
    options: [
      for (final o in json['options'] as List<Object?>? ?? const [])
        if (o is Map<String, Object?>) PollOption.fromJson(o),
    ],
    totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
    myVote: json['myVote'] as String?,
    closesAt: _time(json['closesAt']),
    closed: json['closed'] as bool? ?? false,
  );

  final List<PollOption> options;
  final int totalVotes;

  /// The option the caller picked.
  final String? myVote;
  final DateTime closesAt;
  final bool closed;

  bool get resultsShown => options.any((o) => o.votes != null);

  /// Closed by the server's word, or the time has passed.
  bool isClosed(DateTime now) => closed || !now.isBefore(closesAt);

  Map<String, Object?> toJson() => {
    'options': [for (final o in options) o.toJson()],
    'totalVotes': totalVotes,
    'myVote': myVote,
    'closesAt': closesAt.toUtc().toIso8601String(),
    'closed': closed,
  };
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

/// A post in a list (feed, similar issues, my posts): an issue, a post, a
/// question or a poll.
class IssueCard {
  const IssueCard({
    required this.id,
    required this.category,
    required this.title,
    required this.status,
    required this.createdAt,
    this.kind = PostKind.issue,
    this.private = false,
    this.preview = '',
    this.previewCut = false,
    this.visibility = ContentVisibility.visible,
    this.meTooCount = 0,
    this.commentCount = 0,
    this.imageCount = 0,
    this.thumbnail,
    this.images = const [],
    this.voted = false,
    this.reactions = const {},
    this.myReaction,
    this.following = false,
    this.mine = false,
    this.author,
    this.locationLabel = '',
    this.poll,
    DateTime? statusChangedAt,
  }) : statusChangedAt = statusChangedAt ?? createdAt;

  factory IssueCard.fromJson(Map<String, Object?> json) {
    final images = [
      for (final i in json['images'] as List<Object?>? ?? const [])
        if (i is Map<String, Object?>) IssueImage.fromJson(i),
    ];
    final reactions = <Reaction, int>{};
    if (json['reactions'] case final Map<String, Object?> m) {
      for (final e in m.entries) {
        final r = Reaction.parse(e.key);
        final n = (e.value as num?)?.toInt() ?? 0;
        if (r != null && n > 0) reactions[r] = n;
      }
    }
    return IssueCard(
      id: json['id']! as String,
      kind: json.containsKey('kind')
          ? PostKind.parse(json['kind'] as String?)
          : PostKind.issue,
      category: IssueCategory.parse(json['category'] as String?),
      private: json['private'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      previewCut: json['previewCut'] as bool? ?? false,
      status: IssueStatus.parse(json['status'] as String?),
      visibility: ContentVisibility.parse(json['visibility'] as String?),
      meTooCount: (json['meTooCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? images.length,
      thumbnail: json['thumbnail'] as String?,
      images: images,
      voted: json['voted'] as bool? ?? false,
      reactions: reactions,
      myReaction: Reaction.parse(json['myReaction'] as String?),
      following: json['following'] as bool? ?? false,
      mine: json['mine'] as bool? ?? false,
      author: json['author'] is Map<String, Object?>
          ? PostAuthor.fromJson(json['author']! as Map<String, Object?>)
          : null,
      locationLabel: json['locationLabel'] as String? ?? '',
      poll: json['poll'] is Map<String, Object?>
          ? Poll.fromJson(json['poll']! as Map<String, Object?>)
          : null,
      createdAt: _time(json['createdAt']),
      statusChangedAt: json['statusChangedAt'] == null
          ? null
          : _time(json['statusChangedAt']),
    );
  }

  final String id;
  final PostKind kind;
  final IssueCategory category;
  final bool private;

  /// Issues only; "" for the other kinds.
  final String title;

  /// The first lines of the text (160 characters for issues, 500 for the
  /// others); [previewCut] when there is more.
  final String preview;
  final bool previewCut;
  final IssueStatus status;

  /// Not [ContentVisibility.visible] only for the author's own and staff.
  final ContentVisibility visibility;

  /// Every reaction together (Me too on issues).
  final int meTooCount;
  final int commentCount;
  final int imageCount;

  /// Image id of the first photo, if any.
  final String? thumbnail;

  /// Every photo, in order (servers before 2026-11 send none: use
  /// [thumbnail]).
  final List<IssueImage> images;

  /// The caller reacted (any reaction).
  final bool voted;

  /// How many of each reaction (none at zero).
  final Map<Reaction, int> reactions;
  final Reaction? myReaction;
  final bool following;

  /// Posted by the caller (never says who, for anyone else).
  final bool mine;

  /// Set only on posts made with a name.
  final PostAuthor? author;
  final String locationLabel;

  /// Polls only.
  final Poll? poll;

  /// Rounded to 5 minutes for anonymous posts (by the server).
  final DateTime createdAt;
  final DateTime statusChangedAt;

  bool get anonymous => author == null;
  bool get isIssue => kind == PostKind.issue;

  /// The caller's reaction as shown: issues answer Me too from [voted].
  Reaction? get shownReaction =>
      myReaction ?? (voted ? (isIssue ? Reaction.meToo : Reaction.like) : null);

  /// The most given reactions first (at most [n]).
  List<Reaction> topReactions([int n = 3]) {
    final list = reactions.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in list.take(n)) e.key];
  }

  /// Photo ids to show: every photo, or the thumbnail from older servers.
  List<IssueImage> get shownImages => images.isNotEmpty
      ? images
      : [if (thumbnail != null) IssueImage(id: thumbnail!)];

  IssueCard copyWith({
    bool? voted,
    int? meTooCount,
    Map<Reaction, int>? reactions,
    Reaction? Function()? myReaction,
    bool? following,
    int? commentCount,
    IssueStatus? status,
    Poll? poll,
  }) => IssueCard(
    id: id,
    kind: kind,
    category: category,
    private: private,
    title: title,
    preview: preview,
    previewCut: previewCut,
    status: status ?? this.status,
    visibility: visibility,
    meTooCount: meTooCount ?? this.meTooCount,
    commentCount: commentCount ?? this.commentCount,
    imageCount: imageCount,
    thumbnail: thumbnail,
    images: images,
    voted: voted ?? this.voted,
    reactions: reactions ?? this.reactions,
    myReaction: myReaction != null ? myReaction() : this.myReaction,
    following: following ?? this.following,
    mine: mine,
    author: author,
    locationLabel: locationLabel,
    poll: poll ?? this.poll,
    createdAt: createdAt,
    statusChangedAt: statusChangedAt,
  );

  /// The caller reacts with [r] (null = takes theirs back), counted here at
  /// once; the server's answer replaces it.
  IssueCard reacted(Reaction? r) {
    final counts = Map<Reaction, int>.of(reactions);
    final before = shownReaction;
    if (before != null) {
      final n = (counts[before] ?? 1) - 1;
      if (n > 0) {
        counts[before] = n;
      } else {
        counts.remove(before);
      }
    }
    if (r != null) counts[r] = (counts[r] ?? 0) + 1;
    final total = meTooCount - (before != null ? 1 : 0) + (r != null ? 1 : 0);
    return copyWith(
      voted: r != null,
      meTooCount: total < 0 ? 0 : total,
      reactions: counts,
      myReaction: () => r,
      following: r != null && isIssue ? true : null,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'category': category.wire,
    'private': private,
    'title': title,
    'preview': preview,
    'previewCut': previewCut,
    'status': status.wire,
    'visibility': visibility.name,
    'meTooCount': meTooCount,
    'commentCount': commentCount,
    'imageCount': imageCount,
    'thumbnail': thumbnail,
    'images': [for (final i in images) i.toJson()],
    'voted': voted,
    'reactions': {for (final e in reactions.entries) e.key.wire: e.value},
    'myReaction': myReaction?.wire,
    'following': following,
    'mine': mine,
    'author': author?.toJson(),
    'locationLabel': locationLabel,
    'poll': poll?.toJson(),
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
    this.parentId,
    this.likeCount = 0,
    this.liked = false,
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
    parentId: json['parentId'] as String?,
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    liked: json['liked'] as bool? ?? false,
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

  /// Set on replies: the comment it answers (one level).
  final String? parentId;
  final int likeCount;
  final bool liked;
  final DateTime createdAt;

  bool get official => kind == CommentKind.official;

  IssueComment copyWith({int? likeCount, bool? liked}) => IssueComment(
    id: id,
    body: body,
    createdAt: createdAt,
    kind: kind,
    handle: handle,
    isIssueAuthor: isIssueAuthor,
    mine: mine,
    author: author,
    officialTitle: officialTitle,
    visibility: visibility,
    removedReason: removedReason,
    parentId: parentId,
    likeCount: likeCount ?? this.likeCount,
    liked: liked ?? this.liked,
  );

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
    'parentId': parentId,
    'likeCount': likeCount,
    'liked': liked,
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

/// A new post of any kind (docs/CAMPUS_SOCIAL.md §1).
class IssueDraft {
  const IssueDraft({
    required this.category,
    this.kind = PostKind.issue,
    this.title = '',
    required this.body,
    this.locationLabel = '',
    this.anonymous = true,
    this.imageIds = const [],
    this.pollOptions = const [],
    this.pollDays = 3,
  });

  final PostKind kind;
  final IssueCategory category;

  /// Issues only.
  final String title;
  final String body;
  final String locationLabel;
  final bool anonymous;
  final List<String> imageIds;

  /// Polls: 2–4 answers, and how many days it stays open (1, 3 or 7).
  final List<String> pollOptions;
  final int pollDays;

  static const minTitle = 8;
  static const maxTitle = 120;
  static const minBody = 20;
  static const maxBody = 3000;
  static const maxLocation = 80;
  static const maxPhotos = 4;
  static const minQuestion = 8;
  static const minPollQuestion = 4;
  static const maxPollQuestion = 300;
  static const minPollOptions = 2;
  static const maxPollOptions = 4;
  static const maxPollOption = 80;
  static const pollDayChoices = [1, 3, 7];

  /// The shortest and longest text this kind takes.
  static (int, int) bodyRange(PostKind kind) => switch (kind) {
    PostKind.issue => (minBody, maxBody),
    PostKind.post => (0, maxBody),
    PostKind.question => (minQuestion, maxBody),
    PostKind.poll => (minPollQuestion, maxPollQuestion),
  };

  Map<String, Object?> toJson() => {
    'kind': kind.wire,
    'category': category.wire,
    if (kind == PostKind.issue) 'title': title.trim(),
    'body': body.trim(),
    'locationLabel': locationLabel.trim(),
    'anonymous': anonymous,
    'imageIds': imageIds,
    if (kind == PostKind.poll) ...{
      'pollOptions': [for (final o in pollOptions) o.trim()],
      'pollDays': pollDays,
    },
  };
}
