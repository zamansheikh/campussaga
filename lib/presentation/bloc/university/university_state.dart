part of 'university_bloc.dart';

sealed class UniversityState extends Equatable {
  const UniversityState();
  
  @override
  List<Object> get props => [];
}

final class UniversityInitial extends UniversityState {}

final class UniversityLoading extends UniversityState {}

final class UniversityLoaded extends UniversityState {
  final List<University> universities;

  const UniversityLoaded(this.universities);

  @override
  List<Object> get props => [universities];
}


final class UniversityError extends UniversityState {
  final String message;

  const UniversityError(this.message);

  @override
  List<Object> get props => [message];
}