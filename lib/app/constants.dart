//Firebase
import 'package:campus_saga/app/data/providers/auth/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

var firebaseAuth = FirebaseAuth.instance;
var firebaseStorage = FirebaseStorage.instance;
var fireStore = FirebaseFirestore.instance;

//Controller
var authController = AuthController.instance;

//deFalut Image
final String  defaultPicture = 'https://firebasestorage.googleapis.com/v0/b/campus-saga.appspot.com/o/userProfilePics%2FCampus_Saga.png?alt=media&token=f0586840-7b50-4265-a9a6-5f18a6a6a01b';