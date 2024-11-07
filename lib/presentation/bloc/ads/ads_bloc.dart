import 'package:bloc/bloc.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/domain/usecases/fetch_promotion_usecase.dart';
import 'package:equatable/equatable.dart';

part 'ads_event.dart';
part 'ads_state.dart';

class AdsBloc extends Bloc<AdsEvent, AdsState> {
  final FetchPromotionUsecase fetchPromotionUsecase;

  AdsBloc({
    required this.fetchPromotionUsecase,
  }) : super(AdsInitial()) {
    on<FetchAds>((event, emit)async {
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
  }
}
