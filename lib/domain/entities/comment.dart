import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final String text;
  final DateTime timestamp;

  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, userId, postId, text, timestamp];
}
