// lib/presentation/bloc/post/post_event.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class PostCreated extends PostEvent {
  final Post post;

  const PostCreated(this.post);

  @override
  List<Object?> get props => [post];
}

class FetchPosts extends PostEvent {
  final String universityId;

  const FetchPosts(this.universityId);

  @override
  List<Object?> get props => [universityId];
}
