import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/domain/usecases/admin/fetch_pending_verification_usecase.dart';
import 'package:campus_saga/domain/usecases/admin/update_verification_status_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'verify_user_event.dart';
part 'verify_user_state.dart';

class VerifyUserBloc extends Bloc<VerifyUserEvent, VerifyUserState> {
  final FetchPendingVerificationUsecase fetchPendingVerificationUsecase;
  final UpdateVerificationStatusUsecase updateVerificationStatusUsecase;

  VerifyUserBloc({
    required this.fetchPendingVerificationUsecase,
    required this.updateVerificationStatusUsecase,
  }) : super(VerifyUserInitial()) {
    on<PendingVerificationLoadedEvent>((event, emit) async {
      emit(VerifyUserLoading());
      final result = await fetchPendingVerificationUsecase(event.universtiyId);
      result.fold(
        (failure) => emit(VerifyUserError(message: failure.message)),
        (verifications) => emit(VerifyUserLoaded(verifications: verifications)),
      );
    });

    on<VerifyUserAcceptedEvent>((event, emit) async {
      final vefifications = (state as VerifyUserLoaded).verifications;
      final verification =
          event.verification.copyWith(status: VerificationStatus.verified);
      emit(VerifyUserLoading());
      final result = await updateVerificationStatusUsecase(event.verification);
      result.fold(
        (failure) => emit(VerifyUserError(message: failure.message)),
        (_) {
          emit(VerifyUserLoaded(
              verifications: vefifications
                  .map((v) =>
                      v.userUuid == verification.userUuid ? verification : v)
                  .toList()));
        },
      );
    });

    on<VerifyUserRejectedEvent>((event, emit) async {
      final vefifications = (state as VerifyUserLoaded).verifications;
      final verification =
          event.verification.copyWith(status: VerificationStatus.rejected);
      emit(VerifyUserLoading());
      final result = await updateVerificationStatusUsecase(event.verification);
      result.fold(
        (failure) => emit(VerifyUserError(message: failure.message)),
        (_) {
          emit(VerifyUserLoaded(
              verifications: vefifications
                  .map((v) =>
                      v.userUuid == verification.userUuid ? verification : v)
                  .toList()));
        },
      );
    });
  }
}
