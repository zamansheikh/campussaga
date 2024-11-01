import 'package:equatable/equatable.dart';
import 'package:flutter_lorem/flutter_lorem.dart';

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

final comment1 = Comment(
  id: '1',
  userId: '1',
  postId: '1',
  text: lorem(paragraphs: 1, words: 20),
  timestamp: DateTime.now(),
);

final comment2 = Comment(
  id: '2',
  userId: '2',
  postId: '1',
  text: lorem(paragraphs: 1, words: 20),
  timestamp: DateTime.now(),
);
