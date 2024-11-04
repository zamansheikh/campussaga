// lib/presentation/bloc/post/post_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

class PostingInitial extends PostState {}

class PostingLoading extends PostState {}

class PostingSuccess extends PostState {
  final Post post;

  const PostingSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

class PostingFailure extends PostState {
  final String message;

  const PostingFailure(this.message);

  @override
  List<Object?> get props => [message];
}
