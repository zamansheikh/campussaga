part of 'promotion_bloc.dart';

sealed class PromotionEvent extends Equatable {
  const PromotionEvent();

  @override
  List<Object> get props => [];
}

class PromotionPostCreated extends PromotionEvent {
  final Promotion promotion;
  final List<File>? images;
  const PromotionPostCreated(this.promotion, this.images);
  @override
  List<Object> get props => [promotion, images ?? []];
}