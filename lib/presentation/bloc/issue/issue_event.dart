part of 'issue_bloc.dart';

sealed class IssueEvent extends Equatable {
  const IssueEvent();

  @override
  List<Object> get props => [];
}

class FetchIssueEvent extends IssueEvent {
  final String universityId;

  FetchIssueEvent(this.universityId);

  @override
  List<Object> get props => [universityId];
}

class AddACommentEvent extends IssueEvent {
  final Post post;
  AddACommentEvent(this.post);

  @override
  List<Object> get props => [post];
}

class AddAFeedbackEvent extends IssueEvent {
  final Post post;
  AddAFeedbackEvent(this.post);

  @override
  List<Object> get props => [post];
}
