import 'package:bloc/bloc.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:campus_saga/domain/usecases/fetch_university_usecase.dart';
import 'package:equatable/equatable.dart';

part 'university_event.dart';
part 'university_state.dart';

class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  final FetchUniversityUsecase fetchUniversityUsecase;

  UniversityBloc({
    required this.fetchUniversityUsecase,
  }) : super(UniversityInitial()) {
    on<FetchUniversitiesEvent>((event, emit) async {
      emit(UniversityLoading());
      final result = await fetchUniversityUsecase(null);
      result.fold(
        (failure) => emit(UniversityError(failure.message)),
        (universities) {
          final sortedbyRank = universities
            ..sort((a, b) => b.rankingScore.compareTo(a.rankingScore));
          emit(UniversityLoaded(sortedbyRank));
        },
      );
    });
  }
}
