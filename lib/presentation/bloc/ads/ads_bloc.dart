import 'package:bloc/bloc.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/domain/usecases/promotion/fetch_promotion_usecase.dart';
import 'package:campus_saga/domain/usecases/promotion/update_promotion_usecase.dart';
import 'package:equatable/equatable.dart';

part 'ads_event.dart';
part 'ads_state.dart';

class AdsBloc extends Bloc<AdsEvent, AdsState> {
  final FetchPromotionUsecase fetchPromotionUsecase;
  final UpdatePromotionUsecase updatePromotionUsecase;

  AdsBloc({
    required this.fetchPromotionUsecase,
    required this.updatePromotionUsecase,
  }) : super(AdsInitial()) {
    on<FetchAdsEvent>((event, emit) async {
      emit(AdsLoading());
      final result = await fetchPromotionUsecase("event.universityId");
      result.fold(
        (failure) => emit(AdsError(failure.message)),
        (promotions) {
          print("Promotions fetched successfully!");
          emit(AdsLoaded(promotions));
        },
      );
    });
    on<UpdateAdsEvent>((event, emit) async {
      final allAds = (state as AdsLoaded).promotions;
      final result = await updatePromotionUsecase(event.promotion);
      result.fold(
        (failure) => emit(AdsLoaded(allAds)),
        (_) {
          print("Promotion updated successfully!");
          final updatedAds = allAds.map((ad) {
            return ad.id == event.promotion.id ? event.promotion : ad;
          }).toList();
          emit(AdsLoaded(updatedAds));
        },
      );
    });

    on<MargeAdsEvent>((event, emit) async {
      if (state is AdsLoaded) {
        final allAds = (state as AdsLoaded).promotions;
        final updatedAds = allAds + [event.promotion];
        if(updatedAds.length <1){
              updatedAds.add(event.promotion);
             }else{
               updatedAds.insert(0, event.promotion);
             }
        emit(AdsLoaded(updatedAds));
      }
    });
  }
}
