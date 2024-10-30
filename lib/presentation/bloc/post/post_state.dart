// lib/presentation/bloc/post/post_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostCreatedSuccess extends PostState {
  final Post post;

  const PostCreatedSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

class PostsFetched extends PostState {
  final List<Post> posts;

  const PostsFetched(this.posts);

  @override
  List<Object?> get props => [posts];
}

class PostFailure extends PostState {
  final String message;

  const PostFailure(this.message);

  @override
  List<Object?> get props => [message];
}
