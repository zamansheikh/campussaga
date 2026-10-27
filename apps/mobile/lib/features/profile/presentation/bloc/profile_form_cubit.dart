import 'dart:async';

import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_form_state.dart';

/// Name, department and batch: shared by the first-time setup screen and
/// the edit screen. A Cubit: one submit, no multi-step flow.
class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit(this._repo) : super(const ProfileFormState());

  final ProfileRepository _repo;
  final _suggestionCache = <String, List<String>>{};

  /// Same limits as the server (counted in Unicode code points, like it).
  static const maxLength = {'displayName': 60, 'department': 80, 'batch': 20};

  Future<void> submit({
    required String displayName,
    required String department,
    required String batch,
  }) async {
    if (state.saving) return;
    final values = {
      'displayName': _tidy(displayName),
      'department': _tidy(department),
      'batch': _tidy(batch),
    };
    final errors = <String, ProfileFieldError>{
      for (final e in values.entries)
        if (e.value.isEmpty)
          e.key: ProfileFieldError.required
        else if (e.value.runes.length > maxLength[e.key]!)
          e.key: ProfileFieldError.tooLong,
    };
    if (errors.isNotEmpty) {
      emit(ProfileFormState(fieldErrors: errors));
      return;
    }
    emit(const ProfileFormState(status: ProfileFormStatus.saving));
    try {
      final user = await _repo.updateProfile(
        displayName: values['displayName']!,
        department: values['department']!,
        batch: values['batch']!,
      );
      emit(ProfileFormState(status: ProfileFormStatus.saved, saved: user));
    } on Failure catch (f) {
      emit(ProfileFormState(failure: f));
    } catch (e, s) {
      addError(e, s);
      emit(ProfileFormState(failure: UnexpectedFailure(message: '$e')));
    }
  }

  /// Department suggestions for the autocomplete. Never throws: a failed
  /// lookup just means no suggestions.
  Future<List<String>> suggestDepartments(String query) async {
    final key = _tidy(query).toLowerCase();
    final cached = _suggestionCache[key];
    if (cached != null) return cached;
    try {
      final list = await _repo.departmentSuggestions(key);
      return _suggestionCache[key] = list;
    } on Object {
      return const [];
    }
  }

  static String _tidy(String s) => s.trim().split(RegExp(r'\s+')).join(' ');
}
