import 'package:equatable/equatable.dart';

class AuthorityFeedback extends Equatable {
  final String id;
  final String authorityId; // University authority who provided the feedback
  final String postId;
  final String message;
  final bool resolved; // Whether the issue is marked as resolved
  final int agreeCount; // Agree votes for resolved feedback
  final int disagreeCount; // Disagree votes for resolved feedback
  final DateTime timestamp;

  const AuthorityFeedback({
    required this.id,
    required this.authorityId,
    required this.postId,
    required this.message,
    this.resolved = false,
    this.agreeCount = 0,
    this.disagreeCount = 0,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        authorityId,
        postId,
        message,
        resolved,
        agreeCount,
        disagreeCount,
        timestamp,
      ];
}
