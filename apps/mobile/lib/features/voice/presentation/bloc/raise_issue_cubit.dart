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

final class RaiseState extends Equatable {
  const RaiseState({
    this.step = 0,
    this.category,
    this.title = '',
    this.body = '',
    this.place = '',
    this.anonymous = true,
    this.photos = const [],
    this.similar,
    this.posting = false,
    this.posted,
    this.failure,
    this.restored = false,
  });

  /// 0 category, 1 details, 2 review.
  final int step;
  final IssueCategory? category;
  final String title;
  final String body;
  final String place;
  final bool anonymous;
  final List<DraftPhoto> photos;

  /// Similar issues (null = still looking).
  final List<IssueCard>? similar;
  final bool posting;
  final Issue? posted;
  final Failure? failure;

  /// A saved draft was brought back.
  final bool restored;

  bool get titleOk => title.trim().length >= IssueDraft.minTitle;
  bool get bodyOk => body.trim().length >= IssueDraft.minBody;
  bool get detailsOk => titleOk && bodyOk && !uploading;
  bool get uploading => photos.any((p) => p.uploading);
  bool get canAddPhoto => photos.length < IssueDraft.maxPhotos;

  RaiseState copyWith({
    int? step,
    IssueCategory? category,
    String? title,
    String? body,
    String? place,
    bool? anonymous,
    List<DraftPhoto>? photos,
    List<IssueCard>? Function()? similar,
    bool? posting,
    Issue? posted,
    Failure? Function()? failure,
    bool? restored,
  }) => RaiseState(
    step: step ?? this.step,
    category: category ?? this.category,
    title: title ?? this.title,
    body: body ?? this.body,
    place: place ?? this.place,
    anonymous: anonymous ?? this.anonymous,
    photos: photos ?? this.photos,
    similar: similar != null ? similar() : this.similar,
    posting: posting ?? this.posting,
    posted: posted ?? this.posted,
    failure: failure != null ? failure() : this.failure,
    restored: restored ?? this.restored,
  );

  @override
  List<Object?> get props => [
    step,
    category,
    title,
    body,
    place,
    anonymous,
    photos,
    similar,
    posting,
    posted,
    failure,
    restored,
  ];
}

/// Raise an issue in 3 steps: category → details and photos → review
/// (similar issues, anonymous switch) → post. The text is kept on the phone
/// until it is posted.
class RaiseIssueCubit extends Cubit<RaiseState> {
  RaiseIssueCubit(this._repo, this._cache, this._userId)
    : super(const RaiseState());

  final VoiceRepository _repo;
  final VoiceCache _cache;
  final String _userId;
  int _photoKeys = 0;

  Future<void> start() async {
    final d = await _cache.draft(_userId);
    if (isClosed || d == null || d.isEmpty) return;
    emit(
      state.copyWith(
        category: d.category,
        title: d.title,
        body: d.body,
        place: d.place,
        anonymous: d.anonymous,
        step: d.category == null ? 0 : 1,
        restored: true,
      ),
    );
  }

  void _save() => unawaited(
    _cache.saveDraft(
      _userId,
      VoiceDraft(
        category: state.category,
        title: state.title,
        body: state.body,
        place: state.place,
        anonymous: state.anonymous,
      ),
    ),
  );

  void pickCategory(IssueCategory c) {
    emit(state.copyWith(category: c, step: 1));
    _save();
  }

  void setTitle(String v) {
    emit(state.copyWith(title: v));
    _save();
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

  void back() {
    if (state.step > 0) emit(state.copyWith(step: state.step - 1));
  }

  /// Details → review: look for similar issues meanwhile.
  Future<void> review() async {
    if (!state.detailsOk) return;
    emit(state.copyWith(step: 2, similar: () => null, failure: () => null));
    try {
      final similar = await _repo.similar(state.title);
      if (!isClosed) emit(state.copyWith(similar: () => similar));
    } on Failure {
      if (!isClosed) emit(state.copyWith(similar: () => const []));
    }
  }

  Future<void> addPhoto(PickedPhoto picked) async {
    if (!state.canAddPhoto) return;
    final photo = DraftPhoto(key: ++_photoKeys, bytes: picked.bytes);
    emit(state.copyWith(photos: [...state.photos, photo]));
    await _upload(photo, picked);
  }

  Future<void> _upload(DraftPhoto photo, PickedPhoto picked) async {
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
    emit(
      state.copyWith(
        photos: [for (final p in state.photos) p.key == photo.key ? next : p],
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
      final r = await _repo.vote(card.id, on: !card.voted);
      if (isClosed) return null;
      emit(
        state.copyWith(
          similar: () => [
            for (final c in state.similar ?? const <IssueCard>[])
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
    final category = state.category;
    if (category == null || !state.detailsOk || state.posting) return;
    if (state.photos.any((p) => p.failure != null)) {
      emit(
        state.copyWith(
          failure: () => const RejectedFailure(code: 'UPLOAD_NOT_FOUND'),
        ),
      );
      return;
    }
    emit(state.copyWith(posting: true, failure: () => null));
    try {
      final issue = await _repo.create(
        IssueDraft(
          category: category,
          title: state.title,
          body: state.body,
          locationLabel: state.place,
          anonymous: state.anonymous,
          imageIds: [for (final p in state.photos) p.uploadId!],
        ),
      );
      await _cache.clearDraft();
      if (!isClosed) emit(state.copyWith(posting: false, posted: issue));
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(posting: false, failure: () => f));
    }
  }
}
