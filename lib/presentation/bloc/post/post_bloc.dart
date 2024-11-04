// lib/presentation/bloc/post/post_bloc.dart

import 'package:campus_saga/data/models/post_model.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/usecases/fetch_posts.dart';
import 'package:campus_saga/domain/usecases/upload_post_images.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'post_event.dart';
import 'post_state.dart';
import '../../../domain/usecases/create_post.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final CreatePost createPost;
  final FetchPostsUsecase fetchPosts;
  final UploadPostImages uploadPostImages;

  PostBloc({
    required this.createPost,
    required this.fetchPosts,
    required this.uploadPostImages,
  }) : super(PostInitial()) {
    // on<PostCreated>((event, emit) async {
    //   if (state is PostsFetched) {
    //     final posts = (state as PostsFetched).posts;
    //     emit(PostLoading());
    //     if (event.images != null) {
    //       final result = await uploadPostImages("post_images", event.images!);
    //       result.fold(
    //         (failure) => emit(PostFailure(failure.message)),
    //         (images) async {
    //           Post post = PostModel.fromEntity(event.post)
    //               .copyWith(imageUrls: images)
    //               .toEntity();
    //           final result = await createPost(post);
    //           result.fold(
    //             (failure) => emit(PostFailure(failure.message)),
    //             (post) async{
    //               posts.add(post);
    //               emit(PostCreatedSuccess(post));
    //               // emit(PostsFetched(posts));
    //             },
    //           );
    //         },
    //       );
    //     }
    //   }
    // });

    // In post_bloc.dart
    on<PostCreated>((event, emit) async {
      List<Post> posts = [];
      if (state is PostsFetched) {
        posts = (state as PostsFetched).posts;
      }
      try {
        emit(PostLoading());

        List<String> imageUrls = [];
        if (event.images != null) {
          final imageResult =
              await uploadPostImages("post_images", event.images!);
          await imageResult.fold(
            (failure) async => emit(PostFailure(failure.message)),
            (images) async {
              imageUrls = images;
            },
          );
        }

        Post post = PostModel.fromEntity(event.post)
            .copyWith(imageUrls: imageUrls)
            .toEntity();

        final result = await createPost(post);
        await result.fold(
          (failure) async => emit(PostFailure(failure.message)),
          (createdPost) async {
            posts.add(createdPost);
            emit(PostsFetched(posts));
          },
        );
      } catch (e) {
        emit(PostFailure(e.toString()));
      }
    });

    on<FetchPosts>((event, emit) async {
      emit(PostLoading());
      final result = await fetchPosts(event.universityId);
      result.fold(
        (failure) => emit(PostFailure(failure.message)),
        (posts) {
          print("printting post: $posts");

          emit(PostsFetched(posts));
        },
      );
    });
  }
}
