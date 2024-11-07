import 'package:bloc/bloc.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:campus_saga/domain/usecases/add_universtity_usecase.dart';
import 'package:equatable/equatable.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AddUniverstityUsecase addUniverstityUsecase;
  AdminBloc(
    this.addUniverstityUsecase,
  ) : super(AdminInitial()) {
    on<AddUniversity>((event, emit) async {
      emit(AdminLoading());
      final result = await addUniverstityUsecase(event.university);
      result.fold(
        (failure) => emit(AdminError(failure.message)),
        (university) => emit(AdminSuccess('University added successfully')),
      );
    });
  }
}
