import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:campus_saga/data/models/varification_status_model.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/domain/usecases/auth/create_varification_request_usecase.dart';
import 'package:campus_saga/domain/usecases/auth/upload_verification_images_usecase.dart';
import 'package:equatable/equatable.dart';

part 'varification_event.dart';
part 'varification_state.dart';

class VarificationBloc extends Bloc<VarificationEvent, VarificationState> {
  final UploadVerificationImagesUsecase uploadVerificationImages;
  final CreateVarificationRequestUsecase createVarificationRequest;
  VarificationBloc({
    required this.uploadVerificationImages,
    required this.createVarificationRequest,
  }) : super(VarificationInitial()) {
    on<SubmitVerification>((event, emit) async {
      try {
        emit(VarificationInProgress());
        List<String> imageUrls = [];
        final imageResult = await uploadVerificationImages(
            "${event.verification.userUuid}", event.files);
        await imageResult.fold(
          (failure) async => emit(VarificationError(failure.message)),
          (images) async {
            imageUrls = images;
            final verificationStatus =
                VerificationStatusModel.fromEntity(event.verification)
                    .copyWith(
                      profilePhotoUrl: imageUrls[0],
                      universityIdCardPhotoUrl: imageUrls[1],
                    )
                    .toEntity();
            final result = await createVarificationRequest(verificationStatus);
            result.fold(
              (failure) => emit(VarificationError(failure.message)),
              (verification) => emit(VarificationSuccess(
                  "Verification request submitted successfully")),
            );

          },
        );

        emit(
            VarificationSuccess("Verification request submitted successfully"));
      } catch (e) {
        emit(VarificationError(e.toString()));
      }
    });
  }
}
