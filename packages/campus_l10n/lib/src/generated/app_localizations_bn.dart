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
  String get welcomeTitle => 'শুরু করতে সাইন ইন করো';

  @override
  String get welcomeSubtitle =>
      'যাচাই করা শিক্ষার্থী হিসেবে যোগ দিতে বিশ্ববিদ্যালয়ের ইমেইল ব্যবহার করো। বিশ্ববিদ্যালয়ের ইমেইল নেই? যেকোনো Google অ্যাকাউন্ট দিয়ে চালিয়ে যাও।';

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
      'এই ইমেইল কোনো সমর্থিত বিশ্ববিদ্যালয়ের নয়। বিশ্ববিদ্যালয়ের ইমেইল নেই? ফিরে গিয়ে Google দিয়ে চালিয়ে যাও।';

  @override
  String errorCodeInvalid(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'কোডটি সঠিক নয়। আর $countString বার চেষ্টা করা যাবে।';
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

  @override
  String get setupProfileTitle => 'তোমার প্রোফাইল সাজাও';

  @override
  String get setupProfileSubtitle =>
      'বিভাগ আর ব্যাচ দিলে তোমার ক্লাস খুঁজে পেতে সুবিধা হবে। ক্লাস গ্রুপে সহপাঠীরা তোমার নাম দেখবে; ক্যাম্পাসের সমস্যা তবুও নাম ছাড়া পোস্ট করা যাবে।';

  @override
  String get displayNameLabel => 'তোমার নাম';

  @override
  String get departmentLabel => 'বিভাগ';

  @override
  String get departmentHint => 'যেমন: CSE';

  @override
  String get batchLabel => 'ব্যাচ';

  @override
  String get batchHint => 'যেমন: 61 বা Spring 2024';

  @override
  String get saveProfile => 'সংরক্ষণ করো';

  @override
  String get setupLater => 'পরে';

  @override
  String signedInAs(String email) {
    return '$email দিয়ে সাইন ইন করা আছে';
  }

  @override
  String get useAnotherAccount => 'অন্য অ্যাকাউন্ট ব্যবহার করুন';

  @override
  String get editProfile => 'প্রোফাইল সম্পাদনা';

  @override
  String get profileSaved => 'প্রোফাইল সংরক্ষিত হয়েছে';

  @override
  String get errorFieldRequired => 'এটি পূরণ করা জরুরি।';

  @override
  String get errorFieldTooLong => 'লেখাটি অনেক বড়।';

  @override
  String get deleteAccount => 'অ্যাকাউন্ট মুছে ফেলো';

  @override
  String get deleteAccountTitle => 'অ্যাকাউন্ট মুছে ফেলবে?';

  @override
  String get deleteAccountBody =>
      'এতে তোমার প্রোফাইল স্থায়ীভাবে মুছে যাবে এবং সব ডিভাইস থেকে সাইন আউট হয়ে যাবে। এটি আর ফেরানো যাবে না।';

  @override
  String get deleteAccountConfirm => 'আমার অ্যাকাউন্ট মুছে ফেলো';

  @override
  String get cancel => 'বাতিল';

  @override
  String get updateRequiredTitle => 'আপডেট প্রয়োজন';

  @override
  String get updateRequiredBody =>
      'অ্যাপের এই সংস্করণটি আর সমর্থিত নয়। ব্যবহার চালিয়ে যেতে আপডেট করো।';

  @override
  String get updateNow => 'এখনই আপডেট করো';

  @override
  String get updateFromStore => 'অ্যাপ স্টোর থেকে অ্যাপটি আপডেট করো।';

  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get onboardingSkip => 'এড়িয়ে যাও';

  @override
  String get onboardingNext => 'পরের';

  @override
  String get onboardingStart => 'শুরু করো';

  @override
  String get onboarding1Title => 'তোমার ক্লাস, সবসময় সময়মতো';

  @override
  String get onboarding1Body =>
      'আজকের ক্লাস, সিআর-এর দেওয়া রুম পরিবর্তন, আর প্রতিটি ক্লাসের আগে রিমাইন্ডার।';

  @override
  String get onboarding2Title => 'একসাথে ক্যাম্পাসের সমস্যা তুলে ধরো';

  @override
  String get onboarding2Body =>
      'সমস্যা জানাও, \"আমারও\" যোগ করো, আর সমাধান না হওয়া পর্যন্ত খোঁজ রাখো।';

  @override
  String get onboarding3Title => 'শুধু শিক্ষার্থীদের জন্য, গোপনীয়তা সবার আগে';

  @override
  String get onboarding3Body =>
      'শুধু যাচাই করা বিশ্ববিদ্যালয়ের ইমেইল দিয়ে যোগ দেওয়া যায়। ক্যাম্পাসের সমস্যা নাম ছাড়াই জানাতে পারো। তোমার তথ্য আমরা কখনো বিক্রি করি না।';

  @override
  String get illusNextClass => 'পরের ক্লাস';

  @override
  String get illusStartsIn => '২৫ মিনিট পর';

  @override
  String get illusRoomChanged => 'রুম বদলে ৫০৪';

  @override
  String get illusReminder => 'রিমাইন্ডার চালু';

  @override
  String get illusIssueTitle => 'লাইব্রেরির ওয়াই-ফাই বারবার চলে যায়';

  @override
  String get illusMeToo => 'আমারও';

  @override
  String get illusInProgress => 'কাজ চলছে';

  @override
  String get illusAnonymous => 'নাম গোপন রেখে পোস্ট';

  @override
  String get signInTagline => 'তোমার ক্লাস আর ক্যাম্পাস, এক অ্যাপে।';

  @override
  String signInLegal(String policy) {
    return 'চালিয়ে গেলে তুমি আমাদের $policy-তে সম্মত হচ্ছ।';
  }

  @override
  String get orDivider => 'অথবা';

  @override
  String greetingMorning(String name) {
    return 'শুভ সকাল, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'শুভ দুপুর, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'শুভ সন্ধ্যা, $name';
  }

  @override
  String get todayStepsTitle => 'যেভাবে কাজ করে';

  @override
  String get todayStep1 => 'সিআর-এর দেওয়া কোড দিয়ে ক্লাস গ্রুপে যোগ দাও';

  @override
  String get todayStep2 => 'এক নজরে আজকের ক্লাস আর রুম দেখো';

  @override
  String get todayStep3 => 'প্রতিটি ক্লাসের আগে রিমাইন্ডার পাও';

  @override
  String get verifiedStudent => 'যাচাই করা শিক্ষার্থী';

  @override
  String get completeProfile => 'বিভাগ ও ব্যাচ যোগ করো';

  @override
  String get preferences => 'পছন্দসমূহ';

  @override
  String get about => 'সম্পর্কে';

  @override
  String get languageSystem => 'ফোনের ভাষা';

  @override
  String get themeSystemHint => 'ফোনের সেটিং অনুযায়ী';

  @override
  String versionLabel(String version) {
    return 'ভার্সন $version';
  }

  @override
  String get madeFor => 'বাংলাদেশের শিক্ষার্থীদের জন্য তৈরি';

  @override
  String get deleteAccountHint => 'অ্যাকাউন্ট স্থায়ীভাবে মুছে ফেলো';

  @override
  String get setupProfileStep => 'শেষ ধাপ';

  @override
  String get editProfileHint => 'ক্লাস গ্রুপে সহপাঠীরা তোমার নাম দেখবে।';

  @override
  String get classGroups => 'ক্লাস গ্রুপ';

  @override
  String get joinWithCode => 'কোড দিয়ে যোগ দাও';

  @override
  String get createGroup => 'ক্লাস গ্রুপ তৈরি করো';

  @override
  String get createGroupHint =>
      'সিআর-দের জন্য: সেকশনের রুটিন একবার লিখে কোডটি শেয়ার করো।';

  @override
  String get imTheCr => 'আমি সিআর, গ্রুপ তৈরি করব';

  @override
  String get roleCr => 'সিআর';

  @override
  String membersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString জন শিক্ষার্থী';
  }

  @override
  String classesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'সপ্তাহে $countStringটি ক্লাস',
      zero: 'এখনো কোনো ক্লাস নেই',
    );
    return '$_temp0';
  }

  @override
  String get joinTitle => 'তোমার ক্লাস গ্রুপে যোগ দাও';

  @override
  String get joinSubtitle => 'সিআর-এর দেওয়া ৬ অক্ষরের কোডটি লেখো।';

  @override
  String get joinCodeLabel => 'যোগদানের কোড';

  @override
  String get joinAction => 'গ্রুপে যোগ দাও';

  @override
  String get alreadyMember => 'তুমি এই গ্রুপে আছ';

  @override
  String get openGroup => 'গ্রুপ খোলো';

  @override
  String get createSubtitle =>
      'তুমি হবে সিআর। সহপাঠীরা কোড দিয়ে যোগ দিয়ে তোমার লেখা রুটিন দেখবে।';

  @override
  String get sectionLabel => 'সেকশন';

  @override
  String get sectionHint => 'যেমন A';

  @override
  String get semesterLabel => 'সেমিস্টার';

  @override
  String get semesterHint => 'যেমন Fall 2026';

  @override
  String get createAction => 'গ্রুপ তৈরি করো';

  @override
  String get editGroup => 'গ্রুপের তথ্য সম্পাদনা';

  @override
  String get inviteTitle => 'সহপাঠীদের আমন্ত্রণ জানাও';

  @override
  String get inviteHint => 'ক্লাসের মেসেঞ্জার গ্রুপে এই কোডটি শেয়ার করো।';

  @override
  String get copyInvite => 'আমন্ত্রণ কপি করো';

  @override
  String get inviteCopied => 'আমন্ত্রণ কপি হয়েছে। ক্লাস গ্রুপে পেস্ট করো।';

  @override
  String inviteMessage(String group, String app, String code) {
    return '$app-এ $group গ্রুপে যোগ দাও: অ্যাপ খুলে \"কোড দিয়ে যোগ দাও\" চেপে $code লেখো';
  }

  @override
  String get weeklyRoutine => 'সাপ্তাহিক রুটিন';

  @override
  String get addClass => 'ক্লাস যোগ করো';

  @override
  String get editClass => 'ক্লাস সম্পাদনা';

  @override
  String get noClassesYetCr =>
      'তোমার সেকশনের ক্লাসগুলো যোগ করো। সেমিস্টারে একবার, কয়েক মিনিটের কাজ।';

  @override
  String get noClassesYetMember => 'তোমার সিআর এখনো ক্লাস যোগ করেনি।';

  @override
  String get leaveGroup => 'গ্রুপ ছেড়ে দাও';

  @override
  String get leaveGroupTitle => 'এই গ্রুপ ছেড়ে দেবে?';

  @override
  String get leaveGroupBody =>
      'এর ক্লাসগুলো তোমার রুটিন থেকে সরে যাবে। কোড দিয়ে আবার যোগ দিতে পারবে।';

  @override
  String get deleteGroup => 'গ্রুপ মুছে ফেলো';

  @override
  String get deleteGroupTitle => 'সবার জন্য গ্রুপটি মুছে ফেলবে?';

  @override
  String get deleteGroupBody =>
      'গ্রুপের সব শিক্ষার্থীর কাছ থেকে রুটিনটি মুছে যাবে। এটি আর ফেরানো যাবে না।';

  @override
  String get courseCodeLabel => 'কোর্স কোড';

  @override
  String get courseCodeHint => 'যেমন CSE311';

  @override
  String get courseTitleLabel => 'কোর্সের নাম';

  @override
  String get teacherLabel => 'শিক্ষক';

  @override
  String get roomLabel => 'রুম';

  @override
  String get startsLabel => 'শুরু';

  @override
  String get endsLabel => 'শেষ';

  @override
  String get classTheory => 'থিওরি';

  @override
  String get classLab => 'ল্যাব';

  @override
  String get saveAndAddAnother => 'সংরক্ষণ করে আরেকটি যোগ করো';

  @override
  String get deleteClass => 'ক্লাস মুছে ফেলো';

  @override
  String get errorEndBeforeStart => 'শেষের সময় শুরুর পরে হতে হবে।';

  @override
  String get nextClass => 'পরের ক্লাস';

  @override
  String get nowInClass => 'এখন চলছে';

  @override
  String startsInMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট পর';
  }

  @override
  String startsInHours(int hours, int minutes) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$hoursString ঘণ্টা $minutesString মিনিট পর';
  }

  @override
  String endsInMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট পর শেষ';
  }

  @override
  String get todaysClasses => 'আজকের ক্লাস';

  @override
  String get noClassesToday => 'আজ কোনো ক্লাস নেই';

  @override
  String get doneForToday => 'আজকের ক্লাস শেষ';

  @override
  String nextOn(String day) {
    return 'পরের ক্লাস: $day';
  }

  @override
  String get offlineNotice => 'অফলাইন। সংরক্ষিত রুটিন দেখানো হচ্ছে।';

  @override
  String roomShort(String room) {
    return 'রুম $room';
  }

  @override
  String get routineNoClassesDay => 'এই দিনে কোনো ক্লাস নেই';

  @override
  String get errorGroupNotFound =>
      'তোমার বিশ্ববিদ্যালয়ে এই কোডের কোনো ক্লাস গ্রুপ নেই। সিআর-এর কাছ থেকে কোডটি মিলিয়ে নাও।';

  @override
  String get errorNotCr => 'শুধু সিআর এই গ্রুপ পরিবর্তন করতে পারে।';

  @override
  String get errorGroupLimit =>
      'তুমি ইতিমধ্যে ১০টি ক্লাস গ্রুপে আছ। নতুনটিতে যোগ দিতে একটি ছেড়ে দাও।';

  @override
  String get errorGroupFull => 'এই ক্লাস গ্রুপ পূর্ণ।';

  @override
  String get errorCrCannotLeave =>
      'তুমি একমাত্র সিআর। আগে সদস্য তালিকা থেকে অন্য কাউকে সিআর বানাও, অথবা গ্রুপটি মুছে ফেলো।';

  @override
  String get errorSlotLimit => 'এই রুটিনে সর্বোচ্চ সংখ্যক ক্লাস আছে।';

  @override
  String get deleteClassTitle => 'সবার জন্য এই ক্লাসটি মুছে ফেলবে?';

  @override
  String get reminders => 'ক্লাস রিমাইন্ডার';

  @override
  String remindersOnValue(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট আগে';
  }

  @override
  String get remindersOff => 'বন্ধ';

  @override
  String get remindersSwitch => 'প্রতিটি ক্লাসের আগে মনে করিয়ে দাও';

  @override
  String get remindersSwitchHint => 'ইন্টারনেট ছাড়াও কাজ করে।';

  @override
  String get remindBefore => 'কখন';

  @override
  String get courses => 'কোর্স';

  @override
  String get coursesHint => 'যে কোর্সে যাও না, সেটি বন্ধ করে দাও।';

  @override
  String get noCoursesYet => 'ক্লাস গ্রুপে যোগ দিলে কোর্সগুলো এখানে দেখাবে।';

  @override
  String get notificationsBlocked =>
      'এই অ্যাপের নোটিফিকেশন বন্ধ। ফোনের সেটিংসে চালু করে আবার চেষ্টা করো।';

  @override
  String get tryAgain => 'আবার চেষ্টা করো';

  @override
  String get exactAlarmTitle => 'ঠিক সময়ে মনে করাও';

  @override
  String get exactAlarmHint =>
      'এটি ছাড়া অ্যান্ড্রয়েড কয়েক মিনিট দেরিতে রিমাইন্ডার দেখাতে পারে।';

  @override
  String get allow => 'চালু করো';

  @override
  String get reminderPromptTitle => 'কোনো ক্লাস মিস কোরো না';

  @override
  String get reminderPromptBody =>
      'প্রতিটি ক্লাসের ১০ মিনিট আগে নোটিফিকেশন পাও।';

  @override
  String get turnOn => 'চালু করো';

  @override
  String get notNow => 'এখন না';

  @override
  String notificationTitle(String course, int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট পর $course';
  }

  @override
  String get notificationChannel => 'ক্লাস রিমাইন্ডার';

  @override
  String get notificationChannelHint => 'প্রতিটি ক্লাসের আগে একটি রিমাইন্ডার';

  @override
  String classesAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি ক্লাস যোগ হয়েছে';
  }

  @override
  String get daysLabel => 'দিন';

  @override
  String get daysHint => 'এই সময়ে ক্লাসটি যেসব দিনে হয়, সবগুলো বেছে নাও।';

  @override
  String get errorPickDay => 'অন্তত একটি দিন বেছে নাও।';

  @override
  String get changeCancelled => 'বাতিল';

  @override
  String get changeMoved => 'পরিবর্তিত';

  @override
  String get changeExtra => 'অতিরিক্ত ক্লাস';

  @override
  String get cancelThisClass => 'এই ক্লাস বাতিল করো';

  @override
  String get changeTimeOrRoom => 'দিন, সময় বা রুম বদলাও';

  @override
  String get undoChange => 'পরিবর্তন ফিরিয়ে নাও';

  @override
  String get removeExtraClass => 'অতিরিক্ত ক্লাস সরাও';

  @override
  String get editWeeklyClass => 'সাপ্তাহিক ক্লাস সম্পাদনা';

  @override
  String get addExtraClass => 'অতিরিক্ত ক্লাস যোগ করো';

  @override
  String cancelClassTitle(String course, String date) {
    return '$date তারিখের $course বাতিল করবে?';
  }

  @override
  String get cancelClassBody =>
      'সহপাঠীরা এটি বাতিল হিসেবে দেখবে, আর এর রিমাইন্ডার মুছে যাবে। সাপ্তাহিক রুটিন একই থাকবে।';

  @override
  String get noteLabel => 'সহপাঠীদের জন্য নোট (ঐচ্ছিক)';

  @override
  String get noteHint => 'যেমন: শিক্ষক ছুটিতে';

  @override
  String get keepClass => 'ক্লাস থাকুক';

  @override
  String get confirmCancel => 'ক্লাস বাতিল করো';

  @override
  String onlyThisDay(String date) {
    return 'শুধু $date তারিখের জন্য। সাপ্তাহিক রুটিন একই থাকবে।';
  }

  @override
  String get dateLabel => 'তারিখ';

  @override
  String get upcomingChanges => 'আসন্ন পরিবর্তন';

  @override
  String wasTime(String time) {
    return 'আগে ছিল $time';
  }

  @override
  String get changeSaved => 'সংরক্ষিত। সহপাঠীরা অ্যাপ খুললেই দেখবে।';

  @override
  String get openGroupAction => 'ক্লাস গ্রুপ খোলো';

  @override
  String get announcements => 'ঘোষণা';

  @override
  String get postAction => 'পোস্ট করো';

  @override
  String get newAnnouncement => 'নতুন ঘোষণা';

  @override
  String get announcementHint => 'ক্লাসকে লেখো, যেমন: কাল ক্যালকুলেটর আনবে';

  @override
  String get pinToTop => 'উপরে পিন করো';

  @override
  String get pinToTopHint =>
      'আনপিন না করা পর্যন্ত সবার উপরে থাকবে। একটিই পিন করা যায়।';

  @override
  String get pinAction => 'পিন করো';

  @override
  String get unpinAction => 'আনপিন করো';

  @override
  String get pinnedLabel => 'পিন করা';

  @override
  String get deleteAction => 'মুছে ফেলো';

  @override
  String get deleteAnnouncementTitle => 'সবার জন্য এই ঘোষণা মুছে ফেলবে?';

  @override
  String get noAnnouncements => 'এখনো কোনো ঘোষণা নেই।';

  @override
  String get noAnnouncementsCr =>
      'ক্লাসের আপডেট এখানে পোস্ট করো: কুইজ, কী আনতে হবে, রুমের খবর।';

  @override
  String get announcementPosted => 'পোস্ট হয়েছে। সহপাঠীরা অ্যাপ খুললেই দেখবে।';

  @override
  String get newBadge => 'নতুন';

  @override
  String get timeJustNow => 'এইমাত্র';

  @override
  String timeMinutesAgo(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট আগে';
  }

  @override
  String timeHoursAgo(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString ঘণ্টা আগে';
  }

  @override
  String get timeYesterday => 'গতকাল';

  @override
  String get errorAnnouncementGone => 'এই ঘোষণাটি আগেই মুছে ফেলা হয়েছে।';

  @override
  String get pushChannel => 'ক্লাস আপডেট';

  @override
  String get pushChannelHint => 'সিআর-এর পরিবর্তন ও ঘোষণা';

  @override
  String get myCourses => 'আমার কোর্স';

  @override
  String get myCoursesHint =>
      'এই সেকশনে যে কোর্স নাও না, সেগুলো বন্ধ করো, যেমন শুধু রিটেকের জন্য যোগ দিলে। শুধু তোমার রুটিন ও রিমাইন্ডার বদলাবে।';

  @override
  String coursesShown(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalStringটির মধ্যে $shownStringটি কোর্স তোমার রুটিনে';
  }

  @override
  String get members => 'সদস্য';

  @override
  String get youLabel => 'তুমি';

  @override
  String get makeCr => 'সিআর বানাও';

  @override
  String get makeMember => 'সাধারণ সদস্য বানাও';

  @override
  String get stepDown => 'সিআর পদ ছাড়ো';

  @override
  String get removeFromGroup => 'গ্রুপ থেকে সরাও';

  @override
  String removeMemberTitle(String name) {
    return '$name-কে গ্রুপ থেকে সরাবে?';
  }

  @override
  String get removeMemberBody =>
      'সে আর এই রুটিন দেখবে না। কোড দিয়ে আবার যোগ দিতে পারবে।';

  @override
  String get crHint =>
      'সিআর রুটিন সম্পাদনা, ঘোষণা পোস্ট ও সদস্য পরিচালনা করে। প্রতি গ্রুপে সর্বোচ্চ ৩ জন।';

  @override
  String get unnamedStudent => 'শিক্ষার্থী';

  @override
  String get errorCrLimit => 'একটি গ্রুপে সর্বোচ্চ ৩ জন সিআর থাকতে পারে।';

  @override
  String get errorLastCr => 'আগে অন্য কাউকে সিআর বানাও।';

  @override
  String get errorRemoveCr => 'আগে তাকে সাধারণ সদস্য বানাও, তারপর সরাও।';

  @override
  String get errorPersonalLimit => 'তোমার সর্বোচ্চ সংখ্যক ব্যক্তিগত ক্লাস আছে।';

  @override
  String get newSemester => 'নতুন সেমিস্টার শুরু করো';

  @override
  String get newSemesterBody =>
      'এতে সাপ্তাহিক রুটিন ও এর পরিবর্তনগুলো মুছে যাবে। সদস্য, যোগদানের কোড ও ঘোষণা থাকবে, আর সহপাঠীদের জানানো হবে।';

  @override
  String get startAction => 'শুরু করো';

  @override
  String get personalClasses => 'ব্যক্তিগত';

  @override
  String get addPersonalClass => 'ব্যক্তিগত ক্লাস যোগ করো';

  @override
  String get editPersonalClass => 'ব্যক্তিগত ক্লাস সম্পাদনা';

  @override
  String get personalHint =>
      'এগুলো শুধু তুমি দেখবে: টিউশন, চাকরি, অন্য সেকশনের ল্যাব।';

  @override
  String get personalNameLabel => 'নাম';

  @override
  String get personalNameHint => 'যেমন: টিউশন';

  @override
  String get personalDetailsLabel => 'বিস্তারিত';

  @override
  String get placeLabel => 'জায়গা';

  @override
  String get addToRoutine => 'রুটিনে যোগ করো';

  @override
  String get extraClassHint => 'তোমার ক্লাস গ্রুপের জন্য, শুধু এক দিনের';

  @override
  String get deletePersonalTitle => 'এই ব্যক্তিগত ক্লাসটি মুছে ফেলবে?';

  @override
  String get addAction => 'যোগ করো';

  @override
  String get editAction => 'সম্পাদনা';

  @override
  String get batteryTitle => 'রিমাইন্ডার দেরিতে আসছে?';

  @override
  String batteryBody(String brand, String app) {
    return '$brand ফোন ব্যাকগ্রাউন্ডে অ্যাপ বন্ধ করে দিতে পারে। এই অ্যাপকে ব্যাটারি সীমা ছাড়া চলতে দাও: সেটিংস → অ্যাপস → $app → ব্যাটারি → Unrestricted (বা No restrictions)।';
  }

  @override
  String get openSettings => 'সেটিংস খোলো';

  @override
  String get sendFeedback => 'মতামত পাঠাও';

  @override
  String get sendFeedbackHint =>
      'কোনো সমস্যা পেলে বা কোনো আইডিয়া থাকলে জানাও।';

  @override
  String get notVerified => 'যাচাই করা হয়নি';

  @override
  String get verifyWithUniEmail => 'বিশ্ববিদ্যালয়ের ইমেইল দিয়ে যাচাই করো';

  @override
  String get verifyHint =>
      'বিশ্ববিদ্যালয়ের ইমেইলে পাঠানো কোড দিয়ে যাচাই ব্যাজ পাও।';

  @override
  String get chooseUniversity => 'তোমার বিশ্ববিদ্যালয় বেছে নাও';

  @override
  String get chooseUniversityHint =>
      'তুমি বিশ্ববিদ্যালয়ের ইমেইল ছাড়া সাইন ইন করেছ, তাই বিশ্ববিদ্যালয় বেছে নাও। বিশ্ববিদ্যালয়ের ইমেইল দিয়ে যাচাই না করা পর্যন্ত তুমি যাচাই করা হয়নি হিসেবে দেখাবে।';

  @override
  String get searchUniversity => 'নাম, সংক্ষিপ্ত নাম বা শহর';

  @override
  String get universityPickerHint =>
      'নাম, DIU-এর মতো সংক্ষিপ্ত নাম বা শহর দিয়ে খোঁজো।';

  @override
  String get currentUniversity => 'বর্তমান';

  @override
  String get allUniversities => 'সব বিশ্ববিদ্যালয়';

  @override
  String universityMatches(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি মিলেছে';
  }

  @override
  String get noUniversityFound => 'কোনো বিশ্ববিদ্যালয় পাওয়া যায়নি';

  @override
  String get noUniversityFoundHint =>
      'বানান দেখে নাও, অথবা DIU-এর মতো সংক্ষিপ্ত নাম বা ইমেইল ডোমেইন দিয়ে খোঁজো।';

  @override
  String get askToAddUniversity => 'যোগ করতে বলো';

  @override
  String get addUniversitySubject => 'আমার বিশ্ববিদ্যালয় যোগ করুন';

  @override
  String get universityLabel => 'বিশ্ববিদ্যালয়';

  @override
  String get changeAction => 'বদলাও';

  @override
  String get verifiedNow => 'তুমি এখন যাচাই করা শিক্ষার্থী';

  @override
  String get verifyTitle => 'শিক্ষার্থী পরিচয় যাচাই করো';

  @override
  String get verifySubtitle =>
      'তোমার বিশ্ববিদ্যালয়ের দেওয়া ইমেইল লেখো। সেখানে একটি ৬ অঙ্কের কোড পাঠাব।';

  @override
  String get errorEmailInUse =>
      'এই ইমেইলের আলাদা অ্যাকাউন্ট আছে। সাইন আউট করে সেটি দিয়ে সাইন ইন করো।';

  @override
  String get errorAlreadyVerified => 'তুমি ইতিমধ্যে যাচাই করা।';

  @override
  String get errorUniversityRequired =>
      'আগে প্রোফাইলে তোমার বিশ্ববিদ্যালয় বেছে নাও।';

  @override
  String get errorChooseUniversity => 'চালিয়ে যেতে বিশ্ববিদ্যালয় বেছে নাও।';

  @override
  String get errorNotUniversityEmailVerify =>
      'এই ইমেইল কোনো সমর্থিত বিশ্ববিদ্যালয়ের নয়। বিশ্ববিদ্যালয়ের দেওয়া ইমেইল ব্যবহার করো।';

  @override
  String get changeUniversity => 'বিশ্ববিদ্যালয় বদলাও';

  @override
  String get changeWithEmail => 'নতুন বিশ্ববিদ্যালয়ের ইমেইল দিয়ে';

  @override
  String get changeWithEmailHint => 'নতুন বিশ্ববিদ্যালয়ে যাচাই করা থাকো';

  @override
  String get changeWithoutEmail => 'বিশ্ববিদ্যালয়ের ইমেইল ছাড়া';

  @override
  String get changeWithoutEmailHint =>
      'তালিকা থেকে বেছে নাও; যাচাই করা হয়নি হিসেবে দেখাবে';

  @override
  String leaveVerifiedTitle(String university) {
    return '$university-এ যাবে?';
  }

  @override
  String get leaveVerifiedBody =>
      'নতুন বিশ্ববিদ্যালয়ের ইমেইল দিয়ে যাচাই না করা পর্যন্ত তুমি যাচাই করা হয়নি হিসেবে দেখাবে। তোমার ক্লাস গ্রুপগুলো থাকবে।';

  @override
  String get changeUniversitySubtitle =>
      'নতুন বিশ্ববিদ্যালয়ের ইমেইল লেখো। সেখানে একটি ৬ অঙ্কের কোড পাঠাব।';

  @override
  String get universityChanged => 'বিশ্ববিদ্যালয় বদলানো হয়েছে';

  @override
  String get moveAction => 'বদলাও';

  @override
  String movedToDay(String day) {
    return 'সরানো: $day';
  }

  @override
  String movedFromDay(String day) {
    return 'আগে ছিল: $day';
  }

  @override
  String movedDayNotice(String from, String to) {
    return 'শুধু এই সপ্তাহে: $from থেকে $to। সাপ্তাহিক রুটিন একই থাকবে।';
  }

  @override
  String get dayTapToChange => 'অন্য দিনে সরাতে চাপ দাও';

  @override
  String get dayToday => 'আজ';

  @override
  String get dayTomorrow => 'আগামীকাল';

  @override
  String get testsAndDeadlines => 'পরীক্ষা ও ডেডলাইন';

  @override
  String get comingUp => 'সামনে আসছে';

  @override
  String get addTest => 'পরীক্ষা বা ডেডলাইন যোগ করো';

  @override
  String get editTest => 'পরীক্ষা বা ডেডলাইন সম্পাদনা';

  @override
  String get noTestsYet =>
      'এখনো কোনো পরীক্ষা বা ডেডলাইন নেই। গ্রুপের যে কেউ যোগ করতে পারে।';

  @override
  String get testKindLabel => 'কী ধরনের?';

  @override
  String get kindClassTest => 'ক্লাস টেস্ট';

  @override
  String get kindQuiz => 'কুইজ';

  @override
  String get kindAssignment => 'অ্যাসাইনমেন্ট';

  @override
  String get kindLabReport => 'ল্যাব রিপোর্ট';

  @override
  String get kindPresentation => 'প্রেজেন্টেশন';

  @override
  String get kindMidterm => 'মিডটার্ম';

  @override
  String get kindFinal => 'ফাইনাল পরীক্ষা';

  @override
  String get kindOther => 'অন্যান্য';

  @override
  String get testTimeLabel => 'সময়';

  @override
  String get testNoTime => 'সময় নেই';

  @override
  String get testAddTime => 'সময় যোগ করো';

  @override
  String get testAddEnd => 'শেষের সময় যোগ করো';

  @override
  String get dueLabel => 'জমার সময়';

  @override
  String dueAt(String time) {
    return 'জমা $time';
  }

  @override
  String get topicsLabel => 'বিষয় বা বিস্তারিত (ঐচ্ছিক)';

  @override
  String get topicsHint => 'যেমন অধ্যায় ১–৩, ক্যালকুলেটর আনতে হবে';

  @override
  String get testSaved => 'সংরক্ষিত। সহপাঠীরা নোটিফিকেশন পাবে।';

  @override
  String get testDeleted => 'মুছে ফেলা হয়েছে';

  @override
  String deleteTestTitle(String kind) {
    return 'এই $kind মুছে ফেলবে?';
  }

  @override
  String get deleteTestBody => 'গ্রুপের সবার কাছ থেকে মুছে যাবে।';

  @override
  String addedBy(String name) {
    return 'যোগ করেছে $name';
  }

  @override
  String get testOnlyOwnerHint => 'যে যোগ করেছে বা সিআর-ই শুধু বদলাতে পারে।';

  @override
  String reminderTestTomorrow(String kind, String course) {
    return 'আগামীকাল: $kind · $course';
  }

  @override
  String reminderTestSoon(String kind, String course) {
    return 'শিগগিরই $kind · $course';
  }

  @override
  String reminderTestToday(String kind, String course) {
    return 'আজ: $kind · $course';
  }

  @override
  String get errorAssessmentDate =>
      'আজ থেকে ৬ মাসের মধ্যে একটি তারিখ বেছে নাও।';

  @override
  String get errorAssessmentLimit =>
      'এই গ্রুপে সামনের পরীক্ষা ও ডেডলাইন সর্বোচ্চ সংখ্যায় পৌঁছে গেছে।';

  @override
  String get errorAssessmentGone => 'এটি আগেই মুছে ফেলা হয়েছে।';

  @override
  String get errorNotAssessmentOwner =>
      'যে যোগ করেছে বা সিআর-ই শুধু বদলাতে পারে।';

  @override
  String get errorMoveDate => 'আজ থেকে ৬ মাসের মধ্যে একটি দিন বেছে নাও।';

  @override
  String get navCampus => 'ক্যাম্পাস';

  @override
  String get voiceTitle => 'ক্যাম্পাস ভয়েস';

  @override
  String get voiceSortTrending => 'আলোচিত';

  @override
  String get voiceSortNew => 'নতুন';

  @override
  String get voiceSortSolved => 'সমাধান হয়েছে';

  @override
  String get voiceAllCategories => 'সব';

  @override
  String get voiceSearchHint => 'ইস্যু খুঁজো';

  @override
  String get voiceRaiseIssue => 'ইস্যু তোলো';

  @override
  String get voiceMyIssues => 'আমার ইস্যু';

  @override
  String get voiceSafetyReports => 'নিরাপত্তা রিপোর্ট';

  @override
  String get voiceEmptyFeed => 'এখানে এখনো কোনো ইস্যু নেই';

  @override
  String get voiceEmptyFeedHint =>
      'ক্যাম্পাসে কোনো সমস্যা? তুলে ধরো, তোমার নাম গোপন থাকবে।';

  @override
  String get voiceEmptySearch => 'এই খোঁজার সাথে কোনো ইস্যু মেলেনি';

  @override
  String get voiceEmptyMine => 'তুমি এখনো কোনো ইস্যু তোলোনি';

  @override
  String get voiceEmptyMineHint =>
      'তোমার তোলা ইস্যু এখানে দেখাবে, যাচাইয়ে থাকাগুলোও।';

  @override
  String get voiceCatAcademic => 'একাডেমিক';

  @override
  String get voiceCatHostel => 'হল';

  @override
  String get voiceCatTransport => 'পরিবহন';

  @override
  String get voiceCatFacilities => 'সুযোগ-সুবিধা';

  @override
  String get voiceCatSafety => 'নিরাপত্তা';

  @override
  String get voiceCatAdministration => 'প্রশাসন';

  @override
  String get voiceCatFood => 'খাবার';

  @override
  String get voiceCatIt => 'আইটি / ওয়াই-ফাই';

  @override
  String get voiceCatOther => 'অন্যান্য';

  @override
  String get voiceStatusOpen => 'খোলা';

  @override
  String get voiceStatusAcknowledged => 'দেখা হয়েছে';

  @override
  String get voiceStatusInProgress => 'কাজ চলছে';

  @override
  String get voiceStatusSolved => 'সমাধান হয়েছে';

  @override
  String get voiceStatusRejected => 'বাতিল';

  @override
  String get voiceUnderReview => 'যাচাই হচ্ছে';

  @override
  String get voiceRemoved => 'সরানো হয়েছে';

  @override
  String get voiceHiddenBadge => 'যাচাইয়ের জন্য লুকানো';

  @override
  String get voicePrivate => 'গোপন';

  @override
  String get voiceAnonymous => 'বেনামি';

  @override
  String get voiceYou => 'তুমি';

  @override
  String voiceHandle(String handle) {
    return 'শিক্ষার্থী $handle';
  }

  @override
  String get voiceAuthorTag => 'লেখক';

  @override
  String get voiceDeletedAccount => 'মুছে ফেলা অ্যাকাউন্ট';

  @override
  String get voiceOfficial => 'অফিসিয়াল';

  @override
  String get voiceMeToo => 'আমারও';

  @override
  String voiceMeTooSemantics(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'আমারও, $countString জন শিক্ষার্থী';
  }

  @override
  String get voiceFollow => 'ফলো করো';

  @override
  String get voiceFollowing => 'ফলো করছ';

  @override
  String get voiceComments => 'মন্তব্য';

  @override
  String get voiceStatusHistory => 'অবস্থা';

  @override
  String get voiceRaised => 'ইস্যু তোলা হয়েছে';

  @override
  String voiceStepBy(String who, String when) {
    return '$who · $when';
  }

  @override
  String get voiceActorAuthor => 'লেখক';

  @override
  String get voiceActorModerator => 'মডারেটর';

  @override
  String get voiceActorSystem => 'ক্যাম্পাস সাগা';

  @override
  String get voiceHeldNotice =>
      'যাচাই শেষ না হওয়া পর্যন্ত এটা শুধু তুমি দেখছ। সাধারণত এক দিনের কম সময় লাগে।';

  @override
  String get voiceHeldPersonalInfo =>
      'এতে হয়তো ফোন নম্বর, ইমেইল, লিংক বা আইডি নম্বর আছে।';

  @override
  String get voiceHeldLanguage => 'এতে হয়তো এমন শব্দ আছে যা অনুমোদিত নয়।';

  @override
  String get voiceHeldPhoto => 'এই পোস্টের একটি ছবি আগে একজন মডারেটর দেখবেন।';

  @override
  String get voiceHeldUnverified =>
      'যাচাই করা বিশ্ববিদ্যালয় ইমেইল ছাড়া অ্যাকাউন্টের পোস্ট আগে যাচাই হয়।';

  @override
  String voiceRemovedNotice(String reason) {
    return 'মডারেটররা সরিয়েছেন: $reason';
  }

  @override
  String get voiceRemovedByYou => 'তুমি এই ইস্যুটি মুছে ফেলেছ।';

  @override
  String get voiceHiddenNotice =>
      'রিপোর্ট দেখা শেষ না হওয়া পর্যন্ত লুকানো আছে।';

  @override
  String get voicePrivateNotice =>
      'গোপন: শুধু তুমি, মডারেটর আর তোমার বিশ্ববিদ্যালয়ের কর্মকর্তারা এটা দেখতে পান।';

  @override
  String get voiceCommentHint => 'মন্তব্য লেখো';

  @override
  String voiceCommentAs(String who) {
    return 'মন্তব্য করছ: $who';
  }

  @override
  String get voiceCommentAnonymously => 'বেনামে';

  @override
  String get voiceCommentWithName => 'আমার নামে';

  @override
  String get voiceNoComments => 'এখনো কোনো মন্তব্য নেই';

  @override
  String get voiceCommentRemoved => 'মন্তব্যটি সরানো হয়েছে।';

  @override
  String get voiceCommentUnderReview =>
      'যাচাই শেষ না হওয়া পর্যন্ত এই মন্তব্য শুধু তুমি দেখছ।';

  @override
  String get voiceLoadMore => 'আরও দেখো';

  @override
  String get voiceSend => 'পাঠাও';

  @override
  String get voiceReport => 'রিপোর্ট করো';

  @override
  String get voiceReopen => 'আবার খোলো';

  @override
  String get voiceReopenTitle => 'ইস্যুটি আবার খুলবে?';

  @override
  String get voiceReopenHint => 'কর্মকর্তাদের জানাও এখনো কী সমস্যা';

  @override
  String get voiceDeleteIssueTitle => 'ইস্যুটি মুছে ফেলবে?';

  @override
  String get voiceDeleteIssueBody =>
      'এটা সবার কাছ থেকে সরে যাবে। আর ফেরানো যাবে না।';

  @override
  String get voiceDeleteCommentTitle => 'মন্তব্যটি মুছে ফেলবে?';

  @override
  String get voiceEditIssue => 'ইস্যু সম্পাদনা';

  @override
  String get voiceEditWindow =>
      'পোস্ট করার ৬০ মিনিটের মধ্যে সম্পাদনা করা যায়।';

  @override
  String get voiceReportTitle => 'কেন রিপোর্ট করছ?';

  @override
  String get voiceReportSpam => 'স্প্যাম';

  @override
  String get voiceReportAbuse => 'অপমানজনক বা ঘৃণামূলক';

  @override
  String get voiceReportPersonalInfo => 'কারও ব্যক্তিগত তথ্য প্রকাশ করছে';

  @override
  String get voiceReportFalseInfo => 'ভুল তথ্য';

  @override
  String get voiceReportInappropriate => 'অনুপযুক্ত';

  @override
  String get voiceReportOther => 'অন্য কিছু';

  @override
  String get voiceReportDetails => 'বিস্তারিত (ঐচ্ছিক)';

  @override
  String get voiceReportSent => 'ধন্যবাদ। মডারেটররা দেখবেন।';

  @override
  String get voiceReportAnon => 'রিপোর্ট বেনামি থাকে।';

  @override
  String get voiceChangeStatus => 'অবস্থা বদলাও';

  @override
  String get voiceStatusNote => 'শিক্ষার্থীদের জন্য নোট';

  @override
  String get voiceStatusNoteHint => 'কী করা হচ্ছে, বা কেন';

  @override
  String get voiceNoteRequired => 'কেন বাতিল, তা লেখো।';

  @override
  String get voiceOfficialReply => 'অফিসিয়াল উত্তর';

  @override
  String get voiceOfficialReplyHint =>
      'সবার জন্য উত্তর লেখো। তোমার পদবি আর নাম দেখানো হবে।';

  @override
  String get voiceStatusUpdated => 'অবস্থা বদলানো হয়েছে';

  @override
  String get voiceReplyPosted => 'উত্তর পোস্ট হয়েছে';

  @override
  String get voiceOfficialBadge => 'বিশ্ববিদ্যালয় কর্মকর্তা';

  @override
  String get voiceNewTitle => 'ইস্যু তোলো';

  @override
  String voiceStepOf(int step) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);

    return 'ধাপ $stepString / ৩';
  }

  @override
  String get voiceStepCategory => 'কোন বিষয়ে?';

  @override
  String get voiceSafetyNote =>
      'নিরাপত্তা রিপোর্ট গোপন থাকে: শুধু মডারেটর আর তোমার বিশ্ববিদ্যালয়ের কর্মকর্তারা দেখেন।';

  @override
  String get voiceStepDetails => 'কী সমস্যা, লেখো';

  @override
  String get voiceTitleLabel => 'শিরোনাম';

  @override
  String get voiceTitleHint => 'যেমন: রবিবার থেকে ২ নম্বর হলে পানি নেই';

  @override
  String get voiceBodyLabel => 'বিস্তারিত';

  @override
  String get voiceBodyHint =>
      'কী হচ্ছে, কোথায়, কবে থেকে। কারও নাম, ফোন নম্বর বা রোল নম্বর লিখো না।';

  @override
  String get voicePlaceLabel => 'জায়গা (ঐচ্ছিক)';

  @override
  String get voicePlaceHint => 'যেমন: লাইব্রেরি, ৩য় তলা';

  @override
  String get voicePhotosLabel => 'ছবি';

  @override
  String get voiceAddPhoto => 'ছবি যোগ করো';

  @override
  String get voicePhotosHint =>
      'সর্বোচ্চ ৪টি। ছবি থেকে লোকেশন ও ফোনের তথ্য মুছে ফেলা হয়।';

  @override
  String voicePhoto(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'ছবি $nString';
  }

  @override
  String get voiceRemovePhoto => 'ছবি সরাও';

  @override
  String voiceAtLeast(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'অন্তত $nString অক্ষর লেখো।';
  }

  @override
  String get voiceStepReview => 'পোস্ট করার আগে';

  @override
  String get voiceSimilarTitle => 'একই রকম ইস্যু';

  @override
  String get voiceSimilarHint =>
      'এর কোনোটি একই হলে, নতুন পোস্ট না করে সেখানে আমারও চাপো।';

  @override
  String get voiceNoSimilar => 'একই রকম কোনো ইস্যু পাওয়া যায়নি।';

  @override
  String get voicePostAnon => 'বেনামে পোস্ট করো';

  @override
  String get voicePostAnonHint =>
      'তোমার নাম, ইমেইল বা ক্লাস কখনো দেখানো হয় না।';

  @override
  String get voicePostNamedHint => 'এই ইস্যুতে শিক্ষার্থীরা তোমার নাম দেখবে।';

  @override
  String get voiceHowAnonymity => 'বেনামি কীভাবে কাজ করে';

  @override
  String get voicePost => 'পোস্ট করো';

  @override
  String get voiceNext => 'পরের ধাপ';

  @override
  String get voiceBack => 'আগের ধাপ';

  @override
  String get voicePosted => 'ইস্যু পোস্ট হয়েছে';

  @override
  String get voicePostedHeld => 'পোস্ট হয়েছে। একটু যাচাইয়ের পর অন্যরা দেখবে।';

  @override
  String get voiceUploading => 'ছবি আপলোড হচ্ছে…';

  @override
  String get voiceDraftKept => 'তোমার খসড়া এই ফোনে রাখা আছে।';

  @override
  String get voiceOfflineAction =>
      'তুমি অফলাইনে আছ। সংযোগ পেলে আবার চেষ্টা করো।';

  @override
  String get voiceAnonTitle => 'বেনামি কীভাবে কাজ করে';

  @override
  String get voiceAnonIntro =>
      'ক্যাম্পাস ভয়েস এমনভাবে বানানো, যাতে তুমি নিরাপদে কথা বলতে পারো।';

  @override
  String get voiceAnon1 =>
      'বেনামি পোস্টে তোমার নাম, ইমেইল বা ক্লাস কখনো দেখানো হয় না।';

  @override
  String get voiceAnon2 =>
      'কে কী লিখেছে তা আলাদা করে রাখা হয়। অ্যাপে বা আমাদের অ্যাডমিন প্যানেলে কোনো স্ক্রিন, কর্মী বা বিশ্ববিদ্যালয়ের কর্মকর্তা তা দেখতে পারেন না।';

  @override
  String get voiceAnon3 =>
      'তোমার হ্যান্ডেল (যেমন “শিক্ষার্থী 7KQF”) প্রতিটি ইস্যুতে আলাদা।';

  @override
  String get voiceAnon4 =>
      'ছবি পরিষ্কার করা হয়: লোকেশন ও ফোনের তথ্য মুছে ফেলা হয়।';

  @override
  String get voiceAnon5 => 'সময় দেখানো হয় মোটামুটি, মিনিট ধরে নয়।';

  @override
  String get voiceAnon6 =>
      'নিয়ম ভাঙলে (হুমকি, কারও নাম প্রকাশ, স্প্যাম) তোমার পোস্ট করা বন্ধ হতে পারে, কিন্তু কেউ জানবে না তুমি কে।';

  @override
  String get voiceAnon7 =>
      'তুমি যা লেখো তা থেকেও তোমাকে চেনা যেতে পারে। নিজের নাম, রোল নম্বর বা শুধু তুমিই জানো এমন তথ্য লিখো না। সবার জন্য পোস্টের স্ক্রিনশট যে কেউ নিতে পারে।';

  @override
  String get voiceAnon8 =>
      'নিরাপত্তা রিপোর্ট গোপন থাকে: শুধু মডারেটর আর তোমার বিশ্ববিদ্যালয়ের কর্মকর্তারা দেখেন।';

  @override
  String get errorFeatureDisabled => 'ক্যাম্পাস ভয়েস এখনো চালু হয়নি।';

  @override
  String get errorVoiceBanned =>
      'নিয়ম ভাঙার কারণে এখন তুমি পোস্ট, মন্তব্য বা ভোট করতে পারবে না।';

  @override
  String errorVoiceBannedUntil(String date) {
    return 'নিয়ম ভাঙার কারণে $date পর্যন্ত তুমি পোস্ট, মন্তব্য বা ভোট করতে পারবে না।';
  }

  @override
  String get errorIssueNotFound => 'এই ইস্যুটি দেখা যাচ্ছে না।';

  @override
  String get errorCommentNotFound => 'এই মন্তব্যটি দেখা যাচ্ছে না।';

  @override
  String get errorUploadNotFound =>
      'একটি ছবি পুরো আপলোড হয়নি। সেটি সরিয়ে আবার যোগ করো।';

  @override
  String get errorImageInvalid => 'এই ফাইলটি ব্যবহারযোগ্য ছবি নয়।';

  @override
  String get errorImageTooLarge => 'ছবিটি অনেক বড়।';

  @override
  String get errorPhotoNotAllowed =>
      'এই ছবিটি পোস্ট করা যাবে না। অন্য একটি ছবি বেছে নাও।';

  @override
  String get voicePhotoRefused => 'পোস্ট করা যাবে না';

  @override
  String get errorEditWindowClosed =>
      'পোস্ট করার প্রথম ৬০ মিনিটেই শুধু সম্পাদনা করা যায়।';

  @override
  String get errorReopenNotAllowed =>
      'শুধু সমাধান হওয়া ইস্যু ৩০ দিনের মধ্যে আবার খোলা যায়।';

  @override
  String get errorIssueClosed =>
      'ইস্যুটি সরানো হয়েছে, তাই নতুন মন্তব্য করা যাবে না।';

  @override
  String get errorCannotVoteOwn =>
      'ইস্যুটি তুমিই তুলেছ, তাই তোমাকে আগেই গোনা হয়েছে।';

  @override
  String get errorAlreadyReported => 'তুমি আগেই এটা রিপোর্ট করেছ।';

  @override
  String get errorStatusChangeInvalid => 'এই অবস্থায় বদলানো যায় না।';

  @override
  String get errorNoteRequired => 'কেন, তা জানিয়ে একটি নোট দাও।';

  @override
  String get voiceFromGallery => 'গ্যালারি থেকে বেছে নাও';

  @override
  String get voiceTakePhoto => 'ছবি তোলো';

  @override
  String get voiceHeldModerator => 'মডারেটররা দেখার সময় এটা লুকিয়ে রেখেছেন।';
}
