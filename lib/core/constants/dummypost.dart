import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';

Post dummyPostGenerate(User user) {
  var uuid = Uuid();
  final postId = uuid.v1();
  final feedback1 = Feedback(
    id: uuid.v1(),
    postId: postId,
    message: 'Feedback message',
    authorityId: user.id,
    timestamp: DateTime.now(),
  );
  final comment1 = Comment(
    id: uuid.v1(),
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
