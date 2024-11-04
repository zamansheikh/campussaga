// lib/presentation/bloc/post/post_bloc.dart
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/usecases/fetch_posts.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'issue_event.dart';
part 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final FetchPostsUsecase fetchPosts;
  IssueBloc({
    required this.fetchPosts,
  }) : super(IssueInitial()) {
    on<IssueEvent>((event, emit) {
      emit(IssueLoading());
    });
    on<FetchIssueEvent>((event, emit) async {
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
  }
}
