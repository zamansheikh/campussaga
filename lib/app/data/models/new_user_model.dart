class userModel {
  String? uid;
  String? password;
  String? profilePhoto;
  String? phoneNumber;
  String? gender;
  bool? isVerified;
  String? university;
  String? name;
  String? department;
  String? email;

  userModel(
      {this.uid,
      this.password,
      this.profilePhoto,
      this.phoneNumber,
      this.gender,
      this.isVerified,
      this.university,
      this.name,
      this.department,
      this.email});

  userModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'] as String;
    password = json['password'] as String;
    profilePhoto = json['profilePhoto'] as String;
    phoneNumber = json['phoneNumber'] as String;
    gender = json['gender'] as String;
    isVerified = json['isVerified'];
    university = json['university'] as String;
    name = json['name'] as String;
    department = json['department'] as String;
    email = json['email'] as String;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uid'] = this.uid;
    data['password'] = this.password;
    data['profilePhoto'] = this.profilePhoto;
    data['phoneNumber'] = this.phoneNumber;
    data['gender'] = this.gender;
    data['isVerified'] = this.isVerified;
    data['university'] = this.university;
    data['name'] = this.name;
    data['department'] = this.department;
    data['email'] = this.email;
    return data;
  }
}
