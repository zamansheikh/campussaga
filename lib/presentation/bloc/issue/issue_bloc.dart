// lib/presentation/bloc/post/post_bloc.dart
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/usecases/add_comment_usecase.dart';
import 'package:campus_saga/domain/usecases/fetch_posts.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'issue_event.dart';
part 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final FetchPostsUsecase fetchPosts;
  final AddCommentUsecase addCommentUsecase;
  IssueBloc({
    required this.fetchPosts,
    required this.addCommentUsecase,
  }) : super(IssueInitial()) {
    on<FetchIssueEvent>((event, emit) async {
      emit(IssueLoading());
      final result = await fetchPosts(event.universityId);
      result.fold(
        (failure) => emit(IssueFailure(failure.message)),
        (posts) {
          print("Posts fetched successfully!");
          //remove duplicates
          posts = posts.toSet().toList();
          emit(IssueLoaded(posts));
        },
      );
    });
    on<AddACommentEvent>((event, emit) async {
      final previousPosts = (state as IssueLoaded).posts;
      final result = await addCommentUsecase(event.post);
      result.fold(
        (failure) => emit(IssueLoaded(previousPosts)),
        (_) {
          print("Comment added successfully!");
          final updatedPosts = previousPosts.map((post) {
            if (post.id == event.post.id) {
              //update this post directly from event.post
              post = event.post;
            }
            return post;
          }).toList();
          emit(IssueLoaded(updatedPosts));
        },
      );
    });
  }
}
