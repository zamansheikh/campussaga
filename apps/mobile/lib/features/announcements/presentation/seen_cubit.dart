import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/seen_store.dart';

/// Which announcements the student has seen, per group: everything up to
/// the time stored for that group.
class SeenCubit extends Cubit<Map<String, DateTime>> {
  SeenCubit(this._store) : super(const {});

  final SeenStore _store;

  Future<void> start() async {
    final saved = await _store.read();
    if (!isClosed) emit({...saved, ...state});
  }

  bool isNew(ClassGroup g, Announcement a) {
    final seen = state[g.id];
    return seen == null || a.createdAt.isAfter(seen);
  }

  /// The group page was opened: its announcements are seen.
  void markSeen(ClassGroup g) {
    if (g.announcements.isEmpty) return;
    final newest = g.announcements
        .map((a) => a.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final seen = state[g.id];
    if (seen != null && !newest.isAfter(seen)) return;
    final next = {...state, g.id: newest};
    emit(next);
    unawaited(_store.write(next));
  }
}
