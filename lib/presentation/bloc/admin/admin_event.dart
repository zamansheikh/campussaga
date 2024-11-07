part of 'admin_bloc.dart';

sealed class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

class AddUniversity extends AdminEvent {
  final University university;

  AddUniversity(this.university);

  @override
  List<Object> get props => [university];
}