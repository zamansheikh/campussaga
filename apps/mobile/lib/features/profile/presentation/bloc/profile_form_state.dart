part of 'profile_form_cubit.dart';

enum ProfileFormStatus { idle, saving, saved }

/// Why a field was rejected before sending.
enum ProfileFieldError { required, tooLong }

final class ProfileFormState extends Equatable {
  const ProfileFormState({
    this.status = ProfileFormStatus.idle,
    this.fieldErrors = const {},
    this.failure,
    this.saved,
  });

  final ProfileFormStatus status;

  /// Keyed by 'displayName', 'department', 'batch'.
  final Map<String, ProfileFieldError> fieldErrors;

  /// The server refused or could not be reached.
  final Failure? failure;

  /// Set when status is [ProfileFormStatus.saved].
  final UserProfile? saved;

  bool get saving => status == ProfileFormStatus.saving;

  @override
  List<Object?> get props => [
    status,
    fieldErrors,
    failure?.runtimeType,
    failure?.code,
    saved?.id,
  ];
}
