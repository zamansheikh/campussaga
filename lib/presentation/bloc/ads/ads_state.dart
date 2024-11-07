part of 'ads_bloc.dart';

sealed class AdsState extends Equatable {
  const AdsState();
  
  @override
  List<Object> get props => [];
}

final class AdsInitial extends AdsState {}

final class AdsLoading extends AdsState {}

final class AdsLoaded extends AdsState {
  final List<Promotion> promotions;

  const AdsLoaded(this.promotions);

  @override
  List<Object> get props => [promotions];
}

final class AdsError extends AdsState {
  final String message;

  const AdsError(this.message);

  @override
  List<Object> get props => [message];
}