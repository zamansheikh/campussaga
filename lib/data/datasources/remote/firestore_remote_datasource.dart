// lib/data/datasources/remote/firestore_remote_datasource.dart
import 'dart:math';
import 'package:campus_saga/core/usecases/usecase.dart';
import 'package:campus_saga/data/models/post_model.dart';
import 'package:campus_saga/data/models/promotion_model.dart';
import 'package:campus_saga/data/models/role_change_model.dart';
import 'package:campus_saga/data/models/varification_status_model.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comment_model.dart';
import '../../models/feedback_model.dart';
import '../../models/university_model.dart';
import '../../models/user_model.dart';

class FirestoreRemoteDataSource {
  final FirebaseFirestore firestore;

  FirestoreRemoteDataSource({required this.firestore});

  //! User Operations
  Future<UserModel?> getUserProfile(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return UserModel.fromJson(userDoc.data()!);
    }
    return null;
  }

  Future<void> createUser(UserModel user) async {
    await firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUserRole(UserRoleParams role) async {
    await firestore.collection('users').doc(role.uuid).update(
      {'userType': role.role},
    );
  }

  Future<void> updateUserVerificationStatus(
      VerificationStatusModel verification) async {
    await firestore
        .collection('verification')
        .doc(verification.userUuid)
        .update(verification.toJson());
    await firestore.collection('users').doc(verification.userUuid).update({
      'isVerified': verification.status == VerificationStatus.verified,
    });
  }

  //! Post Operations
  Future<void> createPost(PostModel post) async {
    await firestore.collection('posts').doc(post.id).set(post.toJson());
    await firestore.collection('users').doc(post.userId).update({
      'postCount': FieldValue.increment(1),
    });
    await firestore.collection('universities').doc(post.universityId).update({
      'totalPosts': FieldValue.increment(1),
    });
  }

  Future<void> deleteIssue(PostModel post) async {
    await firestore.collection('posts').doc(post.id).delete();
  }

  Future<List<PostModel>> fetchPosts(String universityId) async {
    final querySnapshot = await firestore
        .collection('posts')
        .where('universityId', isEqualTo: universityId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();
  }

  Future<List<PostModel>> getTimelinePosts(String universityId) async {
    List<PostModel> timelinePosts = [];
    final latestPostsSnapshot = await firestore
        .collection('posts')
        .where('universityId', isEqualTo: universityId)
        .orderBy('timestamp', descending: true)
        .limit(2)
        .get();
    final latestPosts = latestPostsSnapshot.docs
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();
    timelinePosts.addAll(latestPosts);

    final topVotedPostsSnapshot = await firestore
        .collection('posts')
        .where('universityId', isEqualTo: universityId)
        .orderBy('trueVotes', descending: true)
        .limit(4)
        .get();
    final topVotedPosts = topVotedPostsSnapshot.docs
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();
    timelinePosts.addAll(topVotedPosts);

    final randomPostSnapshot = await firestore
        .collection('posts')
        .where('universityId', isEqualTo: universityId)
        .get();
    if (randomPostSnapshot.size > 0) {
      final randomIndex = Random().nextInt(randomPostSnapshot.size);
      final randomPost =
          PostModel.fromJson(randomPostSnapshot.docs[randomIndex].data());
      timelinePosts.add(randomPost);
    }

    final remainingPostsSnapshot = await firestore
        .collection('posts')
        .where('universityId', isEqualTo: universityId)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(latestPostsSnapshot.docs.isNotEmpty
            ? latestPostsSnapshot.docs.last
            : topVotedPostsSnapshot.docs.last)
        .get();
    final remainingPosts = remainingPostsSnapshot.docs
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();
    timelinePosts.addAll(remainingPosts);

    return timelinePosts;
  }

  // Comment and Feedback Operations
  Future<void> updatePostComments(PostModel post) async {
    await firestore.collection('posts').doc(post.id).update(
      {'comments': post.comments.map((c) => c.toJson()).toList()},
    );
  }

  Future<void> addComment(String postId, CommentModel comment) async {
    await firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([comment.toJson()]),
    });
  }

  Future<void> updatePostFeedback(PostModel post) async {
    if (post.feedback != null) {
      await firestore.collection('posts').doc(post.id).update(
        {'feedback': post.feedback!.toJson()},
      );
    }
  }

  Future<void> addFeedback(
      String postId, AuthorityFeedbackModel feedback) async {
    await firestore.collection('posts').doc(postId).update({
      'feedback': feedback.toJson(),
    });
  }

  Future<void> updateAgreeOrDisagree(
      PostModel post, UserModel user, bool isAgree) async {
    await firestore.collection('posts').doc(post.id).update(
      {
        'agree': post.agree,
        'disagree': post.disagree,
      },
    );
  }

  Future<void> updateTrueOrFalse(
      PostModel post, UserModel user, bool isTrue) async {
    await firestore.collection('posts').doc(post.id).update(
      {
        'trueVotes': post.trueVotes,
        'falseVotes': post.falseVotes,
      },
    );
   
      await firestore.collection('users').doc(post.userId).update({
        'receivedVotesCount': FieldValue.increment(1),
      });
  
      await firestore.collection('users').doc(user.id).update({
        'givenVotesCount': FieldValue.increment(1),
      });
    
  }

  // University Operations
  Future<void> addUniversity(UniversityModel university) async {
    await firestore
        .collection('universities')
        .doc(university.id)
        .set(university.toJson());
  }

  Future<List<UniversityModel>> getAllUniversity() async {
    final querySnapshot = await firestore.collection('universities').get();
    return querySnapshot.docs
        .map((doc) => UniversityModel.fromJson(doc.data()))
        .toList();
  }

  // Vote Operations
  Future<void> addVote(String postId, String userId, bool isTrueVote) async {
    await firestore.collection('posts').doc(postId).update({
      'votes': FieldValue.arrayUnion([userId]),
    });

    if (isTrueVote) {
      await firestore.collection('posts').doc(postId).update({
        'trueVotes': FieldValue.increment(1),
      });
    } else {
      await firestore.collection('posts').doc(postId).update({
        'falseVotes': FieldValue.increment(1),
      });
    }
  }

  Future<void> updatePostStatus(String postId, bool isResolved) async {
    await firestore.collection('posts').doc(postId).update({
      'isResolved': isResolved,
    });
  }

  Future<void> updateIssuePost(PostModel post) async {
    await firestore.collection('posts').doc(post.id).update(post.toJson());
  }

  //Create a promotion post
  Future<List<PromotionModel>> getPromotionByUniversity(
      String universityId) async {
    final querySnapshot = await firestore
        .collection('promotion')
        // .where('universityId', isEqualTo: universityId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PromotionModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> createPromotion(PromotionModel promotion) async {
    //create doc baseed on the post id
    await firestore
        .collection('promotion')
        .doc(promotion.id)
        .set(promotion.toJson());
  }

  Future<void> updatePromotion(PromotionModel promotion) async {
    await firestore
        .collection('promotion')
        .doc(promotion.id)
        .update(promotion.toJson());
  }

  //addVarificationRequest
  Future<void> addVarificationRequest(
      VerificationStatusModel verification) async {
    await firestore
        .collection('verification')
        .doc(verification.userUuid)
        .set(verification.toJson());
  }

  //get getPendingVerificaionByUniversity
  Future<List<VerificationStatusModel>> getPendingVerificaionByUniversity(
      String universityId) async {
    try {
      final querySnapshot = await firestore
          .collection("verification")
          .where('status', isEqualTo: "pending")
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VerificationStatusModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Failed to Loead Pending Verifications");
    }
  }

  void updateVerificationStatus(VerificationStatusModel verification) async {
    await firestore
        .collection('verification')
        .doc(verification.userUuid)
        .update(verification.toJson());
    await firestore.collection('users').doc(verification.userUuid).update({
      'isVerified': verification.status == VerificationStatus.verified,
    });
  }

  Future<void> changeRoleRequest(RoleChangeModel role) async {
    //create doc baseed on the post id
    await firestore.collection('role').doc(role.uuid).set(role.toJson());
  }

  Future<List<RoleChangeModel>> loadAllRoleChangeRequest() async {
    final querySnapshot = await firestore
        .collection('role')
        .where('status', isEqualTo: 'pending')
        .get();
    return querySnapshot.docs
        .map((doc) => RoleChangeModel.fromJson(doc.data()))
        .toList();
  }
}
