import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_lorem/flutter_lorem.dart';

class Post extends Equatable {
  final String id;
  final String userId;
  final String universityId;
  final String postTitle;
  final String description;
  final bool isResolved;
  final DateTime timestamp;
  final List<String> imageUrls; // List of images attached to the post
  final int trueVotes; // True votes for the post issue
  final int falseVotes; // False votes for the post issue
  final List<Comment> comments; // Comments on the post
  final Feedback? feedback; // Authority feedback, if any

  const Post({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.postTitle,
    required this.description,
    this.isResolved = false,
    required this.timestamp,
    this.imageUrls = const [],
    this.trueVotes = 0,
    this.falseVotes = 0,
    this.comments = const [],
    this.feedback,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        universityId,
        postTitle,
        description,
        isResolved,
        timestamp,
        imageUrls,
        trueVotes,
        falseVotes,
        comments,
        feedback,
      ];
}

final post1 = Post(
  id: '1',
  userId: '1',
  universityId: '1',
  postTitle: lorem(paragraphs: 1, words: 15),
  description: lorem(paragraphs: 3, words: 200),
  timestamp: DateTime.now(),
  imageUrls: [
    "https://loremflickr.com/200/200?random=2",
    "https://loremflickr.com/200/200?random=3",
    "https://loremflickr.com/200/200?random=4",
  ],
  trueVotes: 10,
  falseVotes: 5,
  comments: [comment1, comment2],
  feedback: feedback1,
);
