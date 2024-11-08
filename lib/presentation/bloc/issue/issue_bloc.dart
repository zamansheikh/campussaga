// lib/presentation/bloc/post/post_bloc.dart
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/usecases/add_comment_usecase.dart';
import 'package:campus_saga/domain/usecases/add_feedback_usecase.dart';
import 'package:campus_saga/domain/usecases/fetch_posts.dart';
import 'package:campus_saga/domain/usecases/update_issue_post_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'issue_event.dart';
part 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final FetchPostsUsecase fetchPosts;
  final AddCommentUsecase addCommentUsecase;
  final AddFeedbackUsecase addFeedbackUsecase;
  final UpdateIssuePostUsecase updateIssuePostUsecase;

  IssueBloc({
    required this.fetchPosts,
    required this.addCommentUsecase,
    required this.addFeedbackUsecase,
    required this.updateIssuePostUsecase,
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
      print("Printing ${event.post.disagree}");
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
    on<AddAFeedbackEvent>((event, emit) async {
      final previousPosts = (state as IssueLoaded).posts;
      final result = await addFeedbackUsecase(event.post);
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
    on<UpdatePostEvent>((event, emit) async {
      final previousPosts = (state as IssueLoaded).posts;
      final result = await updateIssuePostUsecase(event.post);
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
