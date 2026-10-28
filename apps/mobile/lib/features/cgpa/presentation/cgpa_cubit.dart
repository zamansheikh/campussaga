import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cgpa_store.dart';

class CgpaState {
  const CgpaState({this.book = const CgpaBook(), this.loaded = false});

  final CgpaBook book;
  final bool loaded;
}

/// The student's CGPA record: every change is saved at once.
class CgpaCubit extends Cubit<CgpaState> {
  CgpaCubit(this._store, this._userId) : super(const CgpaState());

  final CgpaStore _store;
  final String _userId;
  int _ids = 0;

  Future<void> load() async {
    final book = await _store.read(_userId);
    if (isClosed) return;
    emit(CgpaState(book: book ?? const CgpaBook(), loaded: true));
  }

  /// A new id for a semester or course.
  String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_ids++}';

  CgpaBook get _book => state.book;

  void _set(CgpaBook book) {
    emit(CgpaState(book: book, loaded: true));
    unawaited(_store.write(_userId, book));
  }

  Semester? semester(String id) =>
      _book.semesters.where((s) => s.id == id).firstOrNull;

  String addSemester(String name) {
    final s = Semester(id: newId(), name: name.trim());
    _set(_book.copyWith(semesters: [..._book.semesters, s]));
    return s.id;
  }

  void renameSemester(String id, String name) =>
      _editSemester(id, (s) => s.copyWith(name: name.trim()));

  void deleteSemester(String id) => _set(
    _book.copyWith(
      semesters: _book.semesters.where((s) => s.id != id).toList(),
    ),
  );

  /// Moves a semester one place up (-1) or down (+1).
  void moveSemester(String id, int by) {
    final list = [..._book.semesters];
    final i = list.indexWhere((s) => s.id == id);
    final j = i + by;
    if (i < 0 || j < 0 || j >= list.length) return;
    list.insert(j, list.removeAt(i));
    _set(_book.copyWith(semesters: list));
  }

  /// Adds or replaces (same id) a course.
  void saveCourse(String semesterId, CgpaCourse course) =>
      _editSemester(semesterId, (s) {
        final i = s.courses.indexWhere((c) => c.id == course.id);
        final courses = [...s.courses];
        if (i < 0) {
          courses.add(course);
        } else {
          courses[i] = course;
        }
        return s.copyWith(courses: courses);
      });

  void deleteCourse(String semesterId, String courseId) => _editSemester(
    semesterId,
    (s) =>
        s.copyWith(courses: s.courses.where((c) => c.id != courseId).toList()),
  );

  void addCourses(String semesterId, List<CgpaCourse> courses) => _editSemester(
    semesterId,
    (s) => s.copyWith(courses: [...s.courses, ...courses]),
  );

  void setScale(GradeScale scale) => _set(_book.copyWith(scale: scale));

  void setRetake(RetakeRule rule) => _set(_book.copyWith(retake: rule));

  Future<void> clearAll() async {
    emit(const CgpaState(loaded: true));
    await _store.clear(_userId);
  }

  void _editSemester(String id, Semester Function(Semester) edit) => _set(
    _book.copyWith(
      semesters: [for (final s in _book.semesters) s.id == id ? edit(s) : s],
    ),
  );
}
