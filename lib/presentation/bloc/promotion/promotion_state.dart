part of 'promotion_bloc.dart';

sealed class PromotionState extends Equatable {
  const PromotionState();
  
  @override
  List<Object?> get props => [];
}

final class PromotionInitial extends PromotionState {}

final class PromotionPostingLoading extends PromotionState {}

final class PromotionPostingSuccess extends PromotionState {
  final Promotion promotion;
  const PromotionPostingSuccess(this.promotion);
  @override
  List<Object?> get props => [promotion];
}

final class PromotionPostingFailure extends PromotionState {
  final String message;
  const PromotionPostingFailure(this.message);
  @override
  List<Object?> get props => [message];
}