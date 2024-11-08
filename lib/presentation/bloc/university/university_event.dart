part of 'university_bloc.dart';

sealed class UniversityEvent extends Equatable {
  const UniversityEvent();

  @override
  List<Object> get props => [];
}

class FetchUniversitiesEvent extends UniversityEvent {
  const FetchUniversitiesEvent();

  @override
  List<Object> get props => [];
}