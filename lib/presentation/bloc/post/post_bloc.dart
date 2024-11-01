// lib/presentation/bloc/post/post_bloc.dart

import 'package:campus_saga/domain/usecases/fetch_posts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'post_event.dart';
import 'post_state.dart';
import '../../../domain/usecases/create_post.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final CreatePost createPost;
  final FetchPostsUsecase fetchPosts;

  PostBloc({
    required this.createPost,
    required this.fetchPosts,
  }) : super(PostInitial()) {
    on<PostCreated>((event, emit) async {
      if (state is PostsFetched) {
        final posts = (state as PostsFetched).posts;
        emit(PostLoading());
        final result = await createPost(event.post);
        result.fold(
          (failure) => emit(PostFailure(failure.message)),
          (post) {
            emit(PostCreatedSuccess(post));
            posts.add(post);
            emit(PostsFetched(posts));
          },
        );
      }
    });

    on<FetchPosts>((event, emit) async {
      emit(PostLoading());
      final result = await fetchPosts(event.universityId);
      result.fold(
        (failure) => emit(PostFailure(failure.message)),
        (posts) => emit(PostsFetched(posts)),
      );
    });
  }
}
