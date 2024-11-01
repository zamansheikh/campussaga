import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:uuid/v4.dart';

import '../../domain/entities/user.dart';

Post dummyPostGenerate(User user) {
  final postId = UuidV4().toString();
  final feedback1 = Feedback(
    id: UuidV4().toString(),
    postId: postId,
    message: 'Feedback message',
    authorityId: 'authorityId',
    timestamp: DateTime.now(),
  );
  final comment1 = Comment(
    id: UuidV4().toString(),
    userId: user.id,
    postId: postId,
    text: 'Comment text',
    timestamp: DateTime.now(),
  );

  final post1 = Post(
    id: postId,
    userId: user.id,
    universityId: user.universityId.split('@').last.trim(),
    postTitle: lorem(words: 4, paragraphs: 1),
    description: lorem(words: 50, paragraphs: 2),
    timestamp: DateTime.now(),
    imageUrls: ["https://loremflickr.com/200/200?random=2"],
    comments: [comment1],
    feedback: feedback1,
  );
  return post1;
}
