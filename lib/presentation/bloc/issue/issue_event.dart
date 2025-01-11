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

class AddAVoteEvent extends IssueEvent {
  final Post post;
  AddAVoteEvent(this.post);

  @override
  List<Object> get props => [post];
}

class AddAFeedbackEvent extends IssueEvent {
  final Post post;
  AddAFeedbackEvent(this.post);

  @override
  List<Object> get props => [post];
}

class AddAgreeVoteEvent extends IssueEvent {
  final Post post;
  AddAgreeVoteEvent(this.post);

  @override
  List<Object> get props => [post];
}

class UpdatePostEvent extends IssueEvent {
  final Post post;
  UpdatePostEvent(this.post);

  @override
  List<Object> get props => [post];
}

class DeletePostEvent extends IssueEvent {
  final Post post;
  DeletePostEvent(this.post);

  @override
  List<Object> get props => [post];
}
