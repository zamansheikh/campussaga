import '../../domain/entities/feedback.dart';

class FeedbackModel extends Feedback {
  const FeedbackModel({
    required String id,
    required String authorityId,
    required String postId,
    required String message,
    bool resolved = false,
    int agreeCount = 0,
    int disagreeCount = 0,
    required DateTime timestamp,
  }) : super(
          id: id,
          authorityId: authorityId,
          postId: postId,
          message: message,
          resolved: resolved,
          agreeCount: agreeCount,
          disagreeCount: disagreeCount,
          timestamp: timestamp,
        );

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      authorityId: json['authorityId'] as String,
      postId: json['postId'] as String,
      message: json['message'] as String,
      resolved: json['resolved'] as bool? ?? false,
      agreeCount: json['agreeCount'] as int? ?? 0,
      disagreeCount: json['disagreeCount'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorityId': authorityId,
      'postId': postId,
      'message': message,
      'resolved': resolved,
      'agreeCount': agreeCount,
      'disagreeCount': disagreeCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FeedbackModel.fromEntity(Feedback feedback) {
    return FeedbackModel(
      id: feedback.id,
      authorityId: feedback.authorityId,
      postId: feedback.postId,
      message: feedback.message,
      resolved: feedback.resolved,
      agreeCount: feedback.agreeCount,
      disagreeCount: feedback.disagreeCount,
      timestamp: feedback.timestamp,
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? authorityId,
    String? postId,
    String? message,
    bool? resolved,
    int? agreeCount,
    int? disagreeCount,
    DateTime? timestamp,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      authorityId: authorityId ?? this.authorityId,
      postId: postId ?? this.postId,
      message: message ?? this.message,
      resolved: resolved ?? this.resolved,
      agreeCount: agreeCount ?? this.agreeCount,
      disagreeCount: disagreeCount ?? this.disagreeCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}