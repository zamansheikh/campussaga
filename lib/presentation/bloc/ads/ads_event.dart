part of 'ads_bloc.dart';

sealed class AdsEvent extends Equatable {
  const AdsEvent();

  @override
  List<Object> get props => [];
}


final class FetchAds extends AdsEvent {
  const FetchAds();

  @override
  List<Object> get props => [];

}