
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
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

Promotion promotionGenerate(
    User user, String promotionTitle, String description, String clubName, String eventLink, DateTime expiryDate) {
  var uuid = Uuid();
  final promotionId = uuid.v1();
  final freshPromotion = Promotion(
    id: promotionId,
    userId: user.id,
    universityId: user.universityId.split('@').last.trim(),
    promotionTitle: promotionTitle,
    description: description,
    clubName: clubName,
    timestamp: DateTime.now(),
    expiryDate:  expiryDate,
    imageUrls: [
    ],
    likes: 25,
    dislikes: 5,
    eventLink: eventLink,
  );
  return freshPromotion;
}