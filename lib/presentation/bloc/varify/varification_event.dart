part of 'varification_bloc.dart';

sealed class VarificationEvent extends Equatable {
  const VarificationEvent();

  @override
  List<Object> get props => [];
}

class SubmitVerification extends VarificationEvent {
 final Verification verification;
 final List<File> files ;

  const SubmitVerification({
    required this.verification,
    required this.files,
  });

  @override
  List<Object> get props => [verification];
}