import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/data/models/promotion_model.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/domain/usecases/create_promotion.dart';
import 'package:campus_saga/domain/usecases/upload_post_images.dart';
import 'package:campus_saga/presentation/bloc/ads/ads_bloc.dart';
import 'package:equatable/equatable.dart';

part 'promotion_event.dart';
part 'promotion_state.dart';

class PromotionBloc extends Bloc<PromotionEvent, PromotionState> {
  final UploadPostImages uploadPostImages;
  final CreatePostUsecase createPromotion;
  PromotionBloc({
    required this.uploadPostImages,
    required this.createPromotion,
  }) : super(PromotionInitial()) {
    on<PromotionPostCreated>((event, emit) async {
      try {
        emit(PromotionPostingLoading());
        List<String> imageUrls = [];
        if (event.images != null) {
          final imageResult =
              await uploadPostImages("${event.promotion.id}", event.images!);
          await imageResult.fold(
            (failure) async => emit(PromotionPostingFailure(failure.message)),
            (images) async {
              imageUrls = images;
            },
          );
        }

        Promotion promotion = PromotionModel.fromEntity(event.promotion)
            .copyWith(imageUrls: imageUrls)
            .toEntity();

        final result = await createPromotion(promotion);
        await result.fold(
          (failure) async => emit(PromotionPostingFailure(failure.message)),
          (createdPost) async {
            emit(PromotionPostingSuccess(createdPost));
            sl<AdsBloc>().add(MargeAdsEvent(createdPost));
          },
        );
      } catch (e) {
        emit(PromotionPostingFailure(e.toString()));
      }
    });
  }
}
