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