
import 'package:campus_saga/domain/entities/post.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';

Post postGenerate(
    User user, String postTitle, String description) {
  var uuid = Uuid();
  final postId = uuid.v1();
  final freshPost = Post(
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
  return freshPost;
}
