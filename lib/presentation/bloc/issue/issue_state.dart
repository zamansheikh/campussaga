part of 'issue_bloc.dart';

sealed class IssueState extends Equatable {
  const IssueState();
  
  @override
  List<Object> get props => [];
}

final class IssueInitial extends IssueState {}

final class IssueLoading extends IssueState {}

final class IssueLoaded extends IssueState {
  final List<Post> posts;

  IssueLoaded(this.posts);

  @override
  List<Object> get props => [posts];
}

final class IssueFailure extends IssueState {
  final String message;

  IssueFailure(this.message);

  @override
  List<Object> get props => [message];
}