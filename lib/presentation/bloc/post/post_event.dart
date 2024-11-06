// lib/presentation/bloc/post/post_event.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class PostCreated extends PostEvent {
  final Post post;
  final List<File>? images;

  const PostCreated(this.post, this.images);

  @override
  List<Object?> get props => [post,images];
}