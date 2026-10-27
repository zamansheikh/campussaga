// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ক্যাম্পাস সাগা';

  @override
  String get navToday => 'আজ';

  @override
  String get navRoutine => 'রুটিন';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get todayEmptyTitle => 'এখনো কোনো ক্লাস নেই';

  @override
  String get todayEmptyMessage =>
      'আজকের ক্লাস দেখতে ও রিমাইন্ডার পেতে তোমার ক্লাস গ্রুপে যোগ দাও।';

  @override
  String get joinClassGroup => 'ক্লাস গ্রুপে যোগ দাও';

  @override
  String get routineEmptyTitle => 'তোমার সাপ্তাহিক রুটিন';

  @override
  String get routineEmptyMessage =>
      'ক্লাস গ্রুপে যোগ দিলে পুরো সপ্তাহের রুটিন এখানে দেখাবে।';

  @override
  String get settings => 'সেটিংস';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get language => 'ভাষা';

  @override
  String get comingSoon => 'শীঘ্রই আসছে';

  @override
  String get welcomeTitle =>
      'তোমার বিশ্ববিদ্যালয়ের অ্যাকাউন্ট দিয়ে সাইন ইন করো';

  @override
  String get welcomeSubtitle =>
      'শুধু যাচাই করা শিক্ষার্থীরাই যোগ দিতে পারে। বিশ্ববিদ্যালয়ের ইমেইলই দেখায় তুমি শিক্ষার্থী।';

  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যাও';

  @override
  String get useUniversityEmail => 'বিশ্ববিদ্যালয়ের ইমেইল ব্যবহার করো';

  @override
  String get errorUniversityEmailRequired =>
      'এটি বিশ্ববিদ্যালয়ের অ্যাকাউন্ট নয়। তোমার বিশ্ববিদ্যালয়ের Google অ্যাকাউন্ট বেছে নাও, অথবা বিশ্ববিদ্যালয়ের ইমেইল দিয়ে সাইন ইন করো।';

  @override
  String get errorNetwork => 'ইন্টারনেট সংযোগ নেই। আবার চেষ্টা করো।';

  @override
  String get errorGoogleFailed => 'Google সাইন-ইন কাজ করেনি। আবার চেষ্টা করো।';

  @override
  String get errorSessionEnded => 'তুমি সাইন আউট হয়ে গেছ। আবার সাইন ইন করো।';

  @override
  String get errorGeneric => 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করো।';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get emailSignInTitle => 'ইমেইল দিয়ে সাইন ইন';

  @override
  String get emailStepTitle => 'তোমার বিশ্ববিদ্যালয়ের ইমেইল দাও';

  @override
  String get emailStepSubtitle =>
      'আমরা একটি ৬ সংখ্যার কোড পাঠাব। শুধু বিশ্ববিদ্যালয়ের দেওয়া ইমেইলই কাজ করবে।';

  @override
  String get emailLabel => 'বিশ্ববিদ্যালয়ের ইমেইল';

  @override
  String get emailHint => 'yourname@university.edu.bd';

  @override
  String get sendCode => 'কোড পাঠাও';

  @override
  String get codeStepTitle => 'কোডটি লেখো';

  @override
  String codeSentTo(String email) {
    return '$email ঠিকানায় একটি ৬ সংখ্যার কোড পাঠানো হয়েছে';
  }

  @override
  String get codeLabel => '৬ সংখ্যার কোড';

  @override
  String get verifyCode => 'যাচাই করো';

  @override
  String get resendCode => 'আবার কোড পাঠাও';

  @override
  String resendCodeIn(String time) {
    return '$time পর আবার কোড পাঠানো যাবে';
  }

  @override
  String get useDifferentEmail => 'অন্য ইমেইল ব্যবহার করো';

  @override
  String get codeSpamHint => 'খুঁজে পাচ্ছ না? স্প্যাম ফোল্ডারটা দেখো।';

  @override
  String get errorEmailInvalid => 'একটি সঠিক ইমেইল ঠিকানা দাও।';

  @override
  String get errorNotUniversityEmail =>
      'এই ইমেইলটি কোনো যুক্ত বিশ্ববিদ্যালয়ের নয়। তোমার বিশ্ববিদ্যালয়ের দেওয়া ইমেইল ব্যবহার করো।';

  @override
  String errorCodeInvalid(int count) {
    return 'কোডটি সঠিক নয়। আর $count বার চেষ্টা করা যাবে।';
  }

  @override
  String get errorCodeExpired =>
      'কোডটির মেয়াদ শেষ। নতুন কোড পেতে \"আবার কোড পাঠাও\" চাপো।';

  @override
  String get errorCodeTooManyAttempts =>
      'অনেকবার ভুল কোড দেওয়া হয়েছে। নতুন কোড পেতে \"আবার কোড পাঠাও\" চাপো।';

  @override
  String get errorCodeLimit =>
      'অনেকবার কোড চাওয়া হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করো।';

  @override
  String get errorEmailSendFailed => 'ইমেইল পাঠানো যায়নি। আবার চেষ্টা করো।';

  @override
  String get errorTooManyRequests =>
      'অনেকবার চেষ্টা করা হয়েছে। একটু অপেক্ষা করে আবার চেষ্টা করো।';
}
