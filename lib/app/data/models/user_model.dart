import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? name;
  String? phoneNumber;
  String? profilePhoto;
  String? email;
  String? uid;
  String? password;
  String? gender;
  String? university;
  String? department;
  bool? isVerified;

  User(
      {this.name,
      this.phoneNumber,
      this.profilePhoto,
      this.email,
      this.uid,
      this.password,
      this.gender,
      this.university,
      this.department,
      this.isVerified});

  User.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    phoneNumber = json['phoneNumber'];
    profilePhoto = json['profilePhoto'];
    email = json['email'];
    uid = json['uid'];
    password = json['password'];
    gender = json['gender'];
    university = json['university'];
    department = json['department'];
    isVerified = json['isVerified'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['phoneNumber'] = phoneNumber;
    data['profilePhoto'] = profilePhoto;
    data['email'] = email;
    data['uid'] = uid;
    data['password'] = password;
    data['gender'] = gender;
    data['university'] = university;
    data['department'] = department;
    data['isVerified'] = isVerified;
    return data;
  }

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return User(
      name: snapshot['name'],
      email: snapshot['email'],
      profilePhoto: snapshot['profilePhoto'],
      uid: snapshot['uid'],
    );
  }
}
