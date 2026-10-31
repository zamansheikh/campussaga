import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/voice_cache.dart';

enum FeedStatus { loading, ready, failure }

/// The Campus feed's tabs.
enum FeedTab {
  /// Trending posts of every kind.
  forYou,

  /// Newest first, every kind.
  latest,

  /// Questions, newest first.
  ask,

  /// Issues: open ones by trend, or the solved ones.
  issues,
}

final class FeedState extends Equatable {
  const FeedState({
    this.tab = FeedTab.forYou,
    this.solved = false,
    this.category,
    this.query = '',
    this.safety = false,
    this.status = FeedStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.offline = false,
    this.failure,
  });

  final FeedTab tab;

  /// Issues tab: the solved ones instead of the open ones.
  final bool solved;
  final IssueCategory? category;
  final String query;

  /// Officials and moderators (Issues tab): the private safety reports.
  final bool safety;
  final FeedStatus status;
  final List<IssueCard> items;
  final String? nextCursor;
  final bool loadingMore;

  /// Showing the copy saved on the phone (no internet).
  final bool offline;
  final Failure? failure;

  bool get filtered => category != null || query.isNotEmpty || safety;

  /// What the server is asked for.
  IssueSort get sort => switch (tab) {
    FeedTab.forYou => IssueSort.trending,
    FeedTab.latest || FeedTab.ask => IssueSort.newest,
    FeedTab.issues => solved ? IssueSort.solved : IssueSort.trending,
  };

  Set<PostKind>? get kinds => switch (tab) {
    FeedTab.forYou || FeedTab.latest => null,
    FeedTab.ask => const {PostKind.question},
    FeedTab.issues => const {PostKind.issue},
  };

  /// Where the plain first page is saved on the phone.
  String get cacheKey =>
      tab == FeedTab.issues && solved ? 'issues-solved' : tab.name;

  FeedState copyWith({
    FeedTab? tab,
    bool? solved,
    IssueCategory? Function()? category,
    String? query,
    bool? safety,
    FeedStatus? status,
    List<IssueCard>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    bool? offline,
    Failure? Function()? failure,
  }) => FeedState(
    tab: tab ?? this.tab,
    solved: solved ?? this.solved,
    category: category != null ? category() : this.category,
    query: query ?? this.query,
    safety: safety ?? this.safety,
    status: status ?? this.status,
    items: items ?? this.items,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    offline: offline ?? this.offline,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    tab,
    solved,
    category,
    query,
    safety,
    status,
    items,
    nextCursor,
    loadingMore,
    offline,
    failure,
  ];
}

/// The university's Campus feed: a tab, a topic, a search. The plain first
/// page of each tab is saved for offline reading. Reactions and poll votes
/// show at once and roll back if the server says no.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._repo, this._cache, this._userId, {this.universityId})
    : super(const FeedState());

  final VoiceRepository _repo;
  final VoiceCache _cache;
  final String _userId;

  /// Another university's feed (a visit): read-only, not saved offline.
  final String? universityId;

  bool get _saves => universityId == null;
  int _request = 0;

  Future<VoicePage<IssueCard>> _fetch(FeedState s, {String? cursor}) =>
      _repo.feed(
        sort: s.sort,
        universityId: universityId,
        kinds: s.kinds,
        category: s.category,
        query: s.query,
        cursor: cursor,
        private: s.safety && s.tab == FeedTab.issues,
      );

  Future<void> load() async {
    final request = ++_request;
    final s = state;
    emit(s.copyWith(status: FeedStatus.loading, failure: () => null));
    try {
      final page = await _fetch(s);
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          status: FeedStatus.ready,
          items: page.items,
          nextCursor: () => page.nextCursor,
          offline: false,
        ),
      );
      if (!s.filtered && _saves) {
        await _cache.saveFeed(_userId, s.cacheKey, page.items);
      }
    } on Failure catch (f) {
      if (isClosed || request != _request) return;
      final saved = f is NetworkFailure && !s.filtered && _saves
          ? await _cache.feed(_userId, s.cacheKey)
          : null;
      if (isClosed || request != _request) return;
      emit(
        saved != null
            ? state.copyWith(
                status: FeedStatus.ready,
                items: saved,
                nextCursor: () => null,
                offline: true,
              )
            : state.copyWith(status: FeedStatus.failure, failure: () => f),
      );
    }
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.loadingMore || s.nextCursor == null || s.status != FeedStatus.ready) {
      return;
    }
    final request = _request;
    emit(s.copyWith(loadingMore: true));
    try {
      final page = await _fetch(s, cursor: s.nextCursor);
      if (isClosed || request != _request) return;
      final seen = {for (final i in state.items) i.id};
      emit(
        state.copyWith(
          items: [
            ...state.items,
            for (final i in page.items)
              if (!seen.contains(i.id)) i,
          ],
          nextCursor: () => page.nextCursor,
          loadingMore: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  void setTab(FeedTab tab) {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab, items: const []));
    load();
  }

  /// Issues tab: open or solved.
  void setSolved(bool solved) {
    if (solved == state.solved) return;
    emit(state.copyWith(solved: solved, items: const []));
    load();
  }

  void setCategory(IssueCategory? category) {
    if (category == state.category) return;
    emit(state.copyWith(category: () => category, items: const []));
    load();
  }

  void setQuery(String query) {
    final q = query.trim();
    if (q == state.query) return;
    emit(state.copyWith(query: q));
    load();
  }

  void setSafety(bool on) {
    if (on == state.safety) return;
    emit(state.copyWith(safety: on, items: const []));
    load();
  }

  IssueCard? _card(String id) {
    for (final i in state.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// React (or take it back), shown at once.
  Future<Failure?> react(String id, Reaction? reaction) async {
    final before = _card(id);
    if (before == null) return null;
    updated(before.reacted(reaction));
    try {
      final r = await _repo.react(id, reaction);
      final now = _card(id);
      if (now != null && !isClosed) {
        updated(
          now.copyWith(
            voted: r.voted,
            meTooCount: r.meTooCount,
            reactions: r.reactions,
            myReaction: () => r.myReaction,
          ),
        );
      }
      return null;
    } on Failure catch (f) {
      if (!isClosed) updated(before);
      return f;
    }
  }

  /// Vote in a poll; the results show once the server answers.
  Future<Failure?> votePoll(String id, String optionId) async {
    final before = _card(id);
    final poll = before?.poll;
    if (before == null || poll == null) return null;
    try {
      final next = await _repo.votePoll(id, optionId);
      final now = _card(id);
      if (now != null && !isClosed) updated(now.copyWith(poll: next));
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  /// A post changed elsewhere (opened, reacted, deleted).
  void updated(IssueCard card) => emit(
    state.copyWith(
      items: [for (final i in state.items) i.id == card.id ? card : i],
    ),
  );

  void removed(String id) => emit(
    state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id != id) i,
      ],
    ),
  );
}
