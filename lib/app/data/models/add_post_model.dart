class AddPost {
  String? userId;
  String? userProfilePic;
  String? userName;
  String? heading;
  String? description;
  String? imageUrl;
  bool? isSolved;
  int? upvotes;
  int? downvotes;
  String? adminFeedback;
  bool? userAgreesToFeedback;
  bool? postType;

  AddPost(
      this.userId,
      {this.userProfilePic,
      this.userName,
      this.heading,
      this.description,
      this.imageUrl,
      this.isSolved,
      this.upvotes,
      this.downvotes,
      this.adminFeedback,
      this.userAgreesToFeedback,
      this.postType,
      });

  AddPost.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userProfilePic = json['userProfilePic'];
    userName = json['userName'];
    heading = json['heading'];
    description = json['description'];
    imageUrl = json['imageUrl'];
    isSolved = json['isSolved'];
    upvotes = json['upvotes'];
    downvotes = json['downvotes'];
    adminFeedback = json['adminFeedback'];
    userAgreesToFeedback = json['userAgreesToFeedback'];
    postType = json['postType'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userId'] = userId;
    data['id'] = userProfilePic;
    data['userName'] = userName;
    data['heading'] = heading;
    data['description'] = description;
    data['imageUrl'] = imageUrl;
    data['isSolved'] = isSolved;
    data['upvotes'] = upvotes;
    data['downvotes'] = downvotes;
    data['adminFeedback'] = adminFeedback;
    data['userAgreesToFeedback'] = userAgreesToFeedback;
    data['problemHeading'] = postType;
    return data;
  }
}
