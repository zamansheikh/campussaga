// lib/presentation/bloc/post/post_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'post_event.dart';
import 'post_state.dart';
import '../../../domain/usecases/create_post.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final CreatePost createPost;

  PostBloc({required this.createPost}) : super(PostInitial()) {
    on<PostCreated>((event, emit) async {
      emit(PostLoading());

      final result = await createPost(event.post);
      result.fold(
        (failure) => emit(PostFailure(failure.message)),
        (post) => emit(PostCreatedSuccess(post)),
      );
    });

    on<FetchPosts>((event, emit) async {
      emit(PostLoading());
      // Handle fetching posts with another use case here
      emit(PostsFetched([]));  // Empty list as a placeholder
    });
  }
}
