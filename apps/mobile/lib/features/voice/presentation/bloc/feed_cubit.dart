import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/voice_cache.dart';

enum FeedStatus { loading, ready, failure }

final class FeedState extends Equatable {
  const FeedState({
    this.sort = IssueSort.trending,
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

  final IssueSort sort;
  final IssueCategory? category;
  final String query;

  /// Officials and moderators: the private safety reports.
  final bool safety;
  final FeedStatus status;
  final List<IssueCard> items;
  final String? nextCursor;
  final bool loadingMore;

  /// Showing the copy saved on the phone (no internet).
  final bool offline;
  final Failure? failure;

  bool get filtered => category != null || query.isNotEmpty || safety;

  FeedState copyWith({
    IssueSort? sort,
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
    sort: sort ?? this.sort,
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
    sort,
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

/// The university's issues: Trending / New / Solved, a category, a search.
/// The plain first page of each order is saved for offline reading.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._repo, this._cache, this._userId) : super(const FeedState());

  final VoiceRepository _repo;
  final VoiceCache _cache;
  final String _userId;
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    final s = state;
    emit(s.copyWith(status: FeedStatus.loading, failure: () => null));
    try {
      final page = await _repo.feed(
        sort: s.sort,
        category: s.category,
        query: s.query,
        private: s.safety,
      );
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          status: FeedStatus.ready,
          items: page.items,
          nextCursor: () => page.nextCursor,
          offline: false,
        ),
      );
      if (!s.filtered) await _cache.saveFeed(_userId, s.sort, page.items);
    } on Failure catch (f) {
      if (isClosed || request != _request) return;
      final saved = f is NetworkFailure && !s.filtered
          ? await _cache.feed(_userId, s.sort)
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
      final page = await _repo.feed(
        sort: s.sort,
        category: s.category,
        query: s.query,
        cursor: s.nextCursor,
        private: s.safety,
      );
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

  void setSort(IssueSort sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort, items: const []));
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

  /// An issue changed elsewhere (opened, voted, deleted).
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
