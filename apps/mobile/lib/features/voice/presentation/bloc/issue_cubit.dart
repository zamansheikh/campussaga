import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/voice_cache.dart';

final class IssueState extends Equatable {
  const IssueState({
    this.issue,
    this.comments = const [],
    this.commentsCursor,
    this.loading = true,
    this.loadingMore = false,
    this.sending = false,
    this.offline = false,
    this.deleted = false,
    this.failure,
  });

  final Issue? issue;
  final List<IssueComment> comments;
  final String? commentsCursor;
  final bool loading;
  final bool loadingMore;

  /// A comment, reply or status change is being sent.
  final bool sending;

  /// Showing the copy saved on the phone.
  final bool offline;

  /// The author deleted it: the page closes.
  final bool deleted;

  /// Loading failed (nothing to show).
  final Failure? failure;

  IssueState copyWith({
    Issue? issue,
    List<IssueComment>? comments,
    String? Function()? commentsCursor,
    bool? loading,
    bool? loadingMore,
    bool? sending,
    bool? offline,
    bool? deleted,
    Failure? Function()? failure,
  }) => IssueState(
    issue: issue ?? this.issue,
    comments: comments ?? this.comments,
    commentsCursor: commentsCursor != null
        ? commentsCursor()
        : this.commentsCursor,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    sending: sending ?? this.sending,
    offline: offline ?? this.offline,
    deleted: deleted ?? this.deleted,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    issue,
    comments,
    commentsCursor,
    loading,
    loadingMore,
    sending,
    offline,
    deleted,
    failure,
  ];
}

/// One issue and its comments. Actions return the failure to show (null =
/// done); Me too updates at once and rolls back if the server says no.
class IssueCubit extends Cubit<IssueState> {
  IssueCubit(this._repo, this._cache, this._userId, this.id, {Issue? cached})
    : super(IssueState(issue: cached, loading: true));

  final VoiceRepository _repo;
  final VoiceCache _cache;
  final String _userId;
  final String id;

  /// Every change to the card, for the feed to follow.
  final _cards = StreamController<IssueCard>.broadcast();
  Stream<IssueCard> get cards => _cards.stream;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: () => null));
    try {
      final results = await Future.wait<Object>([
        _repo.issue(id),
        _repo.comments(id),
      ]);
      final issue = results[0] as Issue;
      final page = results[1] as VoicePage<IssueComment>;
      if (isClosed) return;
      emit(
        state.copyWith(
          issue: issue,
          comments: page.items,
          commentsCursor: () => page.nextCursor,
          loading: false,
          offline: false,
        ),
      );
      _cards.add(issue.card);
      await _cache.saveIssue(_userId, issue);
    } on Failure catch (f) {
      await _failed(f);
    }
  }

  Future<void> _failed(Failure f) async {
    if (isClosed) return;
    final saved = f is NetworkFailure ? await _cache.issue(_userId, id) : null;
    if (isClosed) return;
    if (saved != null || (f is NetworkFailure && state.issue != null)) {
      emit(
        state.copyWith(
          issue: saved ?? state.issue,
          loading: false,
          offline: true,
        ),
      );
    } else {
      emit(state.copyWith(loading: false, failure: () => f));
    }
  }

  Future<void> loadMoreComments() async {
    final cursor = state.commentsCursor;
    if (cursor == null || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.comments(id, cursor: cursor);
      if (isClosed) return;
      emit(
        state.copyWith(
          comments: [...state.comments, ...page.items],
          commentsCursor: () => page.nextCursor,
          loadingMore: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  void _setCard(IssueCard card) {
    final issue = state.issue;
    if (issue == null) return;
    emit(state.copyWith(issue: issue.withCard(card)));
    _cards.add(card);
  }

  /// Me too on or off, shown at once.
  Future<Failure?> toggleMeToo() async {
    final card = state.issue?.card;
    if (card == null) return null;
    final on = !card.voted;
    _setCard(
      card.copyWith(
        voted: on,
        meTooCount: card.meTooCount + (on ? 1 : -1),
        following: on || card.following,
      ),
    );
    try {
      final r = await _repo.vote(id, on: on);
      final now = state.issue!.card;
      _setCard(now.copyWith(voted: r.voted, meTooCount: r.meTooCount));
      return null;
    } on Failure catch (f) {
      _setCard(card); // roll back
      return f;
    }
  }

  Future<Failure?> toggleFollow() async {
    final card = state.issue?.card;
    if (card == null) return null;
    final on = !card.following;
    _setCard(card.copyWith(following: on));
    try {
      final following = await _repo.follow(id, on: on);
      _setCard(state.issue!.card.copyWith(following: following));
      return null;
    } on Failure catch (f) {
      _setCard(card);
      return f;
    }
  }

  Future<Failure?> _send(Future<void> Function() action) async {
    if (state.sending) return null;
    emit(state.copyWith(sending: true));
    try {
      await action();
      return null;
    } on Failure catch (f) {
      return f;
    } finally {
      if (!isClosed) emit(state.copyWith(sending: false));
    }
  }

  Future<Failure?> addComment(String body, {required bool anonymous}) =>
      _send(() async {
        final c = await _repo.addComment(id, body, anonymous: anonymous);
        if (isClosed) return;
        final card = state.issue!.card;
        emit(state.copyWith(comments: [...state.comments, c]));
        _setCard(
          card.copyWith(commentCount: card.commentCount + 1, following: true),
        );
      });

  Future<Failure?> deleteComment(String commentId) => _send(() async {
    await _repo.deleteComment(id, commentId);
    if (isClosed) return;
    emit(
      state.copyWith(
        comments: [
          for (final c in state.comments)
            if (c.id != commentId) c,
        ],
      ),
    );
  });

  Future<Failure?> report(ReportReason reason, String details) =>
      _send(() => _repo.report(id, reason, details: details));

  Future<Failure?> reportComment(
    String commentId,
    ReportReason reason,
    String details,
  ) =>
      _send(() => _repo.reportComment(id, commentId, reason, details: details));

  Future<Failure?> reopen(String note) => _send(() async {
    final issue = await _repo.reopen(id, note);
    if (!isClosed) _replace(issue);
  });

  Future<Failure?> edit({
    required String title,
    required String body,
    required String place,
  }) => _send(() async {
    final issue = await _repo.edit(
      id,
      title: title,
      body: body,
      locationLabel: place,
    );
    if (!isClosed) _replace(issue);
  });

  Future<Failure?> delete() => _send(() async {
    await _repo.delete(id);
    if (!isClosed) emit(state.copyWith(deleted: true));
  });

  /// Officials.
  Future<Failure?> changeStatus(IssueStatus to, String note) => _send(() async {
    final issue = await _repo.changeStatus(id, to, note: note);
    if (!isClosed) _replace(issue);
  });

  /// Officials.
  Future<Failure?> officialReply(String body) => _send(() async {
    final c = await _repo.officialReply(id, body);
    if (isClosed) return;
    emit(state.copyWith(comments: [...state.comments, c]));
  });

  void _replace(Issue issue) {
    emit(state.copyWith(issue: issue));
    _cards.add(issue.card);
    unawaited(_cache.saveIssue(_userId, issue));
  }

  @override
  Future<void> close() {
    _cards.close();
    return super.close();
  }
}
