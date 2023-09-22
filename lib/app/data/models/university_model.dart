class University {
  String? id;
  String? name;
  String? logoUrl;
  int? totalPosts;
  int? totalSolvedPosts;
  int? totalUpvotes;
  int? totalResponseTime;
  double? score;
  dynamic totalScore;

  University(
      {this.id,
      this.name,
      this.logoUrl,
      this.totalPosts,
      this.totalSolvedPosts,
      this.totalUpvotes,
      this.totalResponseTime,
      this.score,
      this.totalScore});

  University.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    logoUrl = json['logoUrl'];
    totalPosts = json['totalPosts'];
    totalSolvedPosts = json['totalSolvedPosts'];
    totalUpvotes = json['totalUpvotes'];
    totalResponseTime = json['totalResponseTime'];
    score = json['score'];
    totalScore = json['totalScore'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['logoUrl'] = logoUrl;
    data['totalPosts'] = totalPosts;
    data['totalSolvedPosts'] = totalSolvedPosts;
    data['totalUpvotes'] = totalUpvotes;
    data['totalResponseTime'] = totalResponseTime;
    data['score'] = score;
    data['totalScore'] = totalScore;
    return data;
  }
}
