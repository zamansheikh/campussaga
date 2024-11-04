
import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart' as entity_feedback;
import 'package:campus_saga/domain/entities/post.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';

Post postGenerate(
    User user, String postTitle, String description) {
  var uuid = Uuid();
  final postId = uuid.v1();
  // ignore: unused_local_variable
  final feedback1 = entity_feedback.Feedback(
    id: uuid.v1(),
    postId: postId,
    message: 'Feedback message',
    authorityId: user.id,
    timestamp: DateTime.now(),
  );
  // ignore: unused_local_variable
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
    postTitle: postTitle,
    description: description,
    timestamp: DateTime.now(),
    imageUrls: [],
    comments: [],
    feedback: null,
  );
  return post1;
}
