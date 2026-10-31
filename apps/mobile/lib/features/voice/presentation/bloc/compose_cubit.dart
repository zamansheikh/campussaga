import 'dart:async';
import 'dart:typed_data';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/photo_picker.dart';
import '../../data/voice_cache.dart';

/// A photo in the post, uploaded as soon as it is added.
final class DraftPhoto extends Equatable {
  const DraftPhoto({
    required this.key,
    required this.bytes,
    this.uploadId,
    this.failure,
  });

  final int key;
  final Uint8List bytes;

  /// Set when uploaded.
  final String? uploadId;
  final Failure? failure;

  bool get uploading => uploadId == null && failure == null;

  @override
  List<Object?> get props => [key, uploadId, failure];
}

final class ComposeState extends Equatable {
  const ComposeState({
    this.kind = PostKind.post,
    this.category = IssueCategory.general,
    this.title = '',
    this.body = '',
    this.place = '',
    this.anonymous = true,
    this.photos = const [],
    this.pollOptions = const ['', ''],
    this.pollDays = 3,
    this.similar = const [],
    this.posting = false,
    this.posted,
    this.failure,
    this.restored = false,
  });

  final PostKind kind;

  /// Issues start without one (the student picks it).
  final IssueCategory? category;

  /// Issues only.
  final String title;
  final String body;
  final String place;
  final bool anonymous;
  final List<DraftPhoto> photos;

  /// Polls: 2–4 answers and how many days it stays open.
  final List<String> pollOptions;
  final int pollDays;

  /// Issues: ones like this title already raised.
  final List<IssueCard> similar;
  final bool posting;
  final Issue? posted;
  final Failure? failure;

  /// A saved draft was brought back.
  final bool restored;

  bool get uploading => photos.any((p) => p.uploading);
  bool get canAddPhoto => photos.length < IssueDraft.maxPhotos;
  bool get hasPhoto => photos.any((p) => p.uploadId != null);

  // Counted like the server: in runes.
  int get _bodyLength => body.trim().runes.length;

  bool get titleOk {
    final n = title.trim().runes.length;
    return n >= IssueDraft.minTitle && n <= IssueDraft.maxTitle;
  }

  bool get bodyOk {
    final (min, max) = IssueDraft.bodyRange(kind);
    return _bodyLength >= min && _bodyLength <= max;
  }

  /// The answers as they'd be sent (typed ones).
  List<String> get typedOptions => [
    for (final o in pollOptions)
      if (o.trim().isNotEmpty) o.trim(),
  ];

  bool get optionsOk {
    final typed = typedOptions;
    final unique = {for (final o in typed) o.toLowerCase()};
    return typed.length >= IssueDraft.minPollOptions &&
        unique.length == typed.length &&
        typed.every((o) => o.runes.length <= IssueDraft.maxPollOption);
  }

  bool get canPost {
    if (posting || uploading) return false;
    if (photos.any((p) => p.failure != null)) return false;
    return switch (kind) {
      PostKind.issue => category != null && titleOk && bodyOk,
      PostKind.post => bodyOk && (_bodyLength > 0 || hasPhoto),
      PostKind.question => bodyOk,
      PostKind.poll => bodyOk && optionsOk,
    };
  }

  ComposeState copyWith({
    PostKind? kind,
    IssueCategory? Function()? category,
    String? title,
    String? body,
    String? place,
    bool? anonymous,
    List<DraftPhoto>? photos,
    List<String>? pollOptions,
    int? pollDays,
    List<IssueCard>? similar,
    bool? posting,
    Issue? posted,
    Failure? Function()? failure,
    bool? restored,
  }) => ComposeState(
    kind: kind ?? this.kind,
    category: category != null ? category() : this.category,
    title: title ?? this.title,
    body: body ?? this.body,
    place: place ?? this.place,
    anonymous: anonymous ?? this.anonymous,
    photos: photos ?? this.photos,
    pollOptions: pollOptions ?? this.pollOptions,
    pollDays: pollDays ?? this.pollDays,
    similar: similar ?? this.similar,
    posting: posting ?? this.posting,
    posted: posted ?? this.posted,
    failure: failure != null ? failure() : this.failure,
    restored: restored ?? this.restored,
  );

  @override
  List<Object?> get props => [
    kind,
    category,
    title,
    body,
    place,
    anonymous,
    photos,
    pollOptions,
    pollDays,
    similar,
    posting,
    posted,
    failure,
    restored,
  ];
}

/// Write a post, question, poll or issue on one screen. The text is kept
/// on the phone until it is posted; photos upload as they are added.
class ComposeCubit extends Cubit<ComposeState> {
  ComposeCubit(this._repo, this._cache, this._userId, {PostKind? kind})
    : super(_start(kind ?? PostKind.post));

  final VoiceRepository _repo;
  final VoiceCache _cache;
  final String _userId;
  int _photoKeys = 0;
  Timer? _similarTimer;
  int _similarRequest = 0;

  static ComposeState _start(PostKind kind) => ComposeState(
    kind: kind,
    category: kind == PostKind.issue ? null : IssueCategory.general,
  );

  /// Brings back the saved draft when it is of the same kind.
  Future<void> start() async {
    final d = await _cache.draft(_userId);
    if (isClosed || d == null || d.isEmpty || d.kind != state.kind) return;
    emit(
      state.copyWith(
        category: () => d.category ?? state.category,
        title: d.title,
        body: d.body,
        place: d.place,
        anonymous: d.anonymous,
        pollOptions: d.pollOptions.length >= IssueDraft.minPollOptions
            ? d.pollOptions.take(IssueDraft.maxPollOptions).toList()
            : null,
        restored: true,
      ),
    );
    if (state.kind == PostKind.issue) _findSimilar();
  }

  void _save() => unawaited(
    _cache.saveDraft(
      _userId,
      VoiceDraft(
        kind: state.kind,
        category: state.category,
        title: state.title,
        body: state.body,
        place: state.place,
        anonymous: state.anonymous,
        pollOptions: state.kind == PostKind.poll ? state.pollOptions : const [],
      ),
    ),
  );

  /// Another kind: the text stays; the topic fits the kind.
  void setKind(PostKind kind) {
    if (kind == state.kind) return;
    final c = state.category;
    final fits =
        c != null &&
        (kind == PostKind.issue
            ? IssueCategory.forIssues.contains(c)
            : IssueCategory.forPosts.contains(c));
    emit(
      state.copyWith(
        kind: kind,
        category: () => fits
            ? c
            : kind == PostKind.issue
            ? null
            : IssueCategory.general,
        failure: () => null,
      ),
    );
    _save();
    if (kind == PostKind.issue) _findSimilar();
  }

  void setCategory(IssueCategory c) {
    emit(state.copyWith(category: () => c));
    _save();
  }

  void setTitle(String v) {
    emit(state.copyWith(title: v));
    _save();
    _findSimilar();
  }

  void setBody(String v) {
    emit(state.copyWith(body: v));
    _save();
  }

  void setPlace(String v) {
    emit(state.copyWith(place: v));
    _save();
  }

  void setAnonymous(bool v) {
    emit(state.copyWith(anonymous: v));
    _save();
  }

  void setOption(int i, String v) {
    final list = [...state.pollOptions];
    if (i < 0 || i >= list.length) return;
    list[i] = v;
    emit(state.copyWith(pollOptions: list));
    _save();
  }

  void addOption() {
    if (state.pollOptions.length >= IssueDraft.maxPollOptions) return;
    emit(state.copyWith(pollOptions: [...state.pollOptions, '']));
  }

  void removeOption(int i) {
    if (state.pollOptions.length <= IssueDraft.minPollOptions) return;
    final list = [...state.pollOptions]..removeAt(i);
    emit(state.copyWith(pollOptions: list));
    _save();
  }

  void setPollDays(int days) => emit(state.copyWith(pollDays: days));

  /// Issues: look for the same issue raised before, as the title is typed.
  void _findSimilar() {
    _similarTimer?.cancel();
    final title = state.title.trim();
    if (state.kind != PostKind.issue || title.length < IssueDraft.minTitle) {
      if (state.similar.isNotEmpty) emit(state.copyWith(similar: const []));
      return;
    }
    _similarTimer = Timer(const Duration(milliseconds: 600), () async {
      final request = ++_similarRequest;
      try {
        final similar = await _repo.similar(title);
        if (!isClosed && request == _similarRequest) {
          emit(state.copyWith(similar: similar));
        }
      } on Failure {
        // Only a help: say nothing.
      }
    });
  }

  Future<void> addPhoto(PickedPhoto picked) async {
    if (!state.canAddPhoto) return;
    final photo = DraftPhoto(key: ++_photoKeys, bytes: picked.bytes);
    emit(state.copyWith(photos: [...state.photos, photo]));
    DraftPhoto next;
    try {
      final up = await _repo.upload(
        picked.bytes,
        filename: picked.filename,
        contentType: picked.contentType,
      );
      next = DraftPhoto(key: photo.key, bytes: photo.bytes, uploadId: up.id);
    } on Failure catch (f) {
      next = DraftPhoto(key: photo.key, bytes: photo.bytes, failure: f);
    }
    if (isClosed) return;
    // A photo the photo check refused: say why, not just mark the tile.
    final refused = next.failure?.code == 'PHOTO_NOT_ALLOWED';
    emit(
      state.copyWith(
        photos: [for (final p in state.photos) p.key == photo.key ? next : p],
        failure: refused ? () => next.failure : null,
      ),
    );
  }

  void removePhoto(int key) => emit(
    state.copyWith(
      photos: [
        for (final p in state.photos)
          if (p.key != key) p,
      ],
    ),
  );

  /// Me too on a similar issue instead of posting the same thing again.
  Future<Failure?> meTooSimilar(IssueCard card) async {
    try {
      final r = await _repo.react(card.id, card.voted ? null : Reaction.meToo);
      if (isClosed) return null;
      emit(
        state.copyWith(
          similar: [
            for (final c in state.similar)
              c.id == card.id
                  ? c.copyWith(voted: r.voted, meTooCount: r.meTooCount)
                  : c,
          ],
        ),
      );
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  Future<void> post() async {
    final s = state;
    final category = s.category;
    if (!s.canPost || category == null) return;
    emit(s.copyWith(posting: true, failure: () => null));
    try {
      final issue = await _repo.create(
        IssueDraft(
          kind: s.kind,
          category: category,
          title: s.kind == PostKind.issue ? s.title : '',
          body: s.body,
          locationLabel: s.place,
          anonymous: s.anonymous,
          imageIds: [
            for (final p in s.photos)
              if (p.uploadId != null) p.uploadId!,
          ],
          pollOptions: s.kind == PostKind.poll ? s.typedOptions : const [],
          pollDays: s.pollDays,
        ),
      );
      await _cache.clearDraft();
      if (!isClosed) emit(state.copyWith(posting: false, posted: issue));
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(posting: false, failure: () => f));
    }
  }

  @override
  Future<void> close() {
    _similarTimer?.cancel();
    return super.close();
  }
}
