import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class MyIssuesState extends Equatable {
  const MyIssuesState({
    this.items = const [],
    this.nextCursor,
    this.loading = true,
    this.loadingMore = false,
    this.failure,
  });

  final List<IssueCard> items;
  final String? nextCursor;
  final bool loading;
  final bool loadingMore;
  final Failure? failure;

  @override
  List<Object?> get props => [items, nextCursor, loading, loadingMore, failure];
}

/// The caller's own posts of every kind and state (under review and
/// removed too).
class MyIssuesCubit extends Cubit<MyIssuesState> {
  MyIssuesCubit(this._repo) : super(const MyIssuesState());

  final VoiceRepository _repo;

  Future<void> load() async {
    emit(MyIssuesState(items: state.items));
    try {
      final page = await _repo.myIssues();
      if (!isClosed) {
        emit(
          MyIssuesState(
            items: page.items,
            nextCursor: page.nextCursor,
            loading: false,
          ),
        );
      }
    } on Failure catch (f) {
      if (!isClosed) {
        emit(MyIssuesState(items: state.items, loading: false, failure: f));
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    emit(
      MyIssuesState(
        items: state.items,
        nextCursor: cursor,
        loading: false,
        loadingMore: true,
      ),
    );
    try {
      final page = await _repo.myIssues(cursor: cursor);
      if (!isClosed) {
        emit(
          MyIssuesState(
            items: [...state.items, ...page.items],
            nextCursor: page.nextCursor,
            loading: false,
          ),
        );
      }
    } on Failure {
      if (!isClosed) {
        emit(
          MyIssuesState(items: state.items, nextCursor: cursor, loading: false),
        );
      }
    }
  }

  void updated(IssueCard card) => emit(
    MyIssuesState(
      items: [for (final i in state.items) i.id == card.id ? card : i],
      nextCursor: state.nextCursor,
      loading: state.loading,
    ),
  );

  void _put(IssueCard card) => emit(
    MyIssuesState(
      items: [for (final i in state.items) i.id == card.id ? card : i],
      nextCursor: state.nextCursor,
      loading: state.loading,
      loadingMore: state.loadingMore,
      failure: state.failure,
    ),
  );

  IssueCard? _card(String id) {
    for (final i in state.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// React to one of the caller's posts (not issues), shown at once.
  Future<Failure?> react(String id, Reaction? reaction) async {
    final before = _card(id);
    if (before == null) return null;
    _put(before.reacted(reaction));
    try {
      final r = await _repo.react(id, reaction);
      final now = _card(id);
      if (now != null && !isClosed) {
        _put(
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
      if (!isClosed) _put(before);
      return f;
    }
  }

  Future<Failure?> votePoll(String id, String optionId) async {
    try {
      final poll = await _repo.votePoll(id, optionId);
      final now = _card(id);
      if (now != null && !isClosed) _put(now.copyWith(poll: poll));
      return null;
    } on Failure catch (f) {
      return f;
    }
  }
}
