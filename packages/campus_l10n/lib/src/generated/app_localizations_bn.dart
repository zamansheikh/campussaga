// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ভার্সিটি কথা';

  @override
  String get navToday => 'আজ';

  @override
  String get navRoutine => 'রুটিন';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get navExplore => 'এক্সপ্লোর';

  @override
  String get exploreTitle => 'এক্সপ্লোর';

  @override
  String get exploreSubtitle => 'ভার্সিটি কথার সব সুবিধা, এক জায়গায়।';

  @override
  String get exploreYourTools => 'তোমার টুলস';

  @override
  String get exploreComingSoon => 'আসছে';

  @override
  String get exploreRemindersHint => 'প্রতিটি ক্লাসের আগে';

  @override
  String get exploreGroupsHint => 'সেকশনে যোগ দাও বা পরিচালনা করো';

  @override
  String get exploreIssuesHint => 'তোমার পোস্ট, প্রশ্ন, পোল ও ইস্যু';

  @override
  String get busRoutesTitle => 'বাসের রুট';

  @override
  String get busRoutesBody =>
      'তোমার বিশ্ববিদ্যালয়ের বাসের রুট, স্টপ আর ছাড়ার সময়, তোমার স্টপ থেকে পরের বাসসহ।';

  @override
  String get busRoutesEmptyTitle => 'এখনো কোনো বাসের রুট নেই';

  @override
  String get busRoutesEmptyBody =>
      'তোমার ট্রান্সপোর্ট প্রতিনিধি রুট যোগ করলে এখানে দেখাবে।';

  @override
  String get busAddRoute => 'রুট যোগ করো';

  @override
  String get busToCampus => 'ক্যাম্পাসে';

  @override
  String get busFromCampus => 'ক্যাম্পাস থেকে';

  @override
  String busNextFrom(String stop) {
    return '$stop থেকে পরের বাস';
  }

  @override
  String busNextAt(String time) {
    return 'পরের: $time';
  }

  @override
  String get busNoMoreBuses => 'এই সপ্তাহে আর বাস নেই';

  @override
  String get busMyStop => 'আমার স্টপ';

  @override
  String get busPickStop => 'পরের বাস দেখতে তোমার স্টপ বেছে নাও';

  @override
  String get busChangeStop => 'স্টপ বদলাও';

  @override
  String get busStopsTitle => 'স্টপ';

  @override
  String get busDepartures => 'ছাড়ার সময়';

  @override
  String get busNoStops => 'এখনো কোনো স্টপ নেই';

  @override
  String get busNoTrips => 'এদিকে এখনো কোনো বাস নেই';

  @override
  String get busHidden => 'লুকানো';

  @override
  String get busEditRoute => 'রুট এডিট করো';

  @override
  String get busEditStops => 'স্টপ এডিট করো';

  @override
  String get busEditTimetable => 'সময়সূচি এডিট করো';

  @override
  String get busDeleteRoute => 'রুট মুছে ফেলো';

  @override
  String busDeleteRouteTitle(String name) {
    return 'সবার জন্য $name মুছে ফেলবে?';
  }

  @override
  String get busRouteName => 'রুটের নাম';

  @override
  String get busRouteNameHint => 'যেমন: রুট ৪ · মিরপুর';

  @override
  String get busColor => 'রং';

  @override
  String get busNotes => 'নোট (ঐচ্ছিক)';

  @override
  String get busNotesHint => 'যেমন: পরীক্ষার সময় বাস চলে না';

  @override
  String get busShowRoute => 'রুটটি দেখাও';

  @override
  String get busShowRouteHint =>
      'লুকানো রুট শুধু ট্রান্সপোর্ট প্রতিনিধিরা দেখে।';

  @override
  String get busAddStop => 'স্টপ যোগ করো';

  @override
  String get busStopName => 'স্টপের নাম';

  @override
  String get busLandmark => 'চেনার জায়গা (ঐচ্ছিক)';

  @override
  String get busToCampusMinutes => 'ক্যাম্পাসে যেতে শুরু থেকে কত মিনিট';

  @override
  String get busFromCampusMinutes => 'ক্যাম্পাস ছাড়ার কত মিনিট পর';

  @override
  String get busMinutesHint => 'এদিকে বাস এখানে না থামলে খালি রাখো।';

  @override
  String get busStopsHint =>
      'দূরের প্রান্ত থেকে ক্যাম্পাস পর্যন্ত। টেনে ক্রম বদলাও।';

  @override
  String get busAddDeparture => 'ছাড়ার সময় যোগ করো';

  @override
  String get busDepartsAt => 'ছাড়ে';

  @override
  String get busWeekdays => 'দিন';

  @override
  String get busTripNote => 'নোট (ঐচ্ছিক)';

  @override
  String get busSaved => 'সেভ হয়েছে';

  @override
  String busMinutesValue(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট';
  }

  @override
  String get busEveryDay => 'প্রতিদিন';

  @override
  String get busNotRep =>
      'শুধু তোমার বিশ্ববিদ্যালয়ের ট্রান্সপোর্ট প্রতিনিধি বাসের রুট বদলাতে পারে।';

  @override
  String get busRouteNotFound => 'এই বাসের রুটটি সরানো হয়েছে।';

  @override
  String get busOffline => 'অফলাইন। সেভ করা বাসের রুট দেখাচ্ছে।';

  @override
  String busTripFirstStop(String stop) {
    return '$stop থেকে';
  }

  @override
  String get busSave => 'সংরক্ষণ করো';

  @override
  String get busNameRequired => 'একটা নাম দাও।';

  @override
  String get busPickDay => 'অন্তত একটা দিন বেছে নাও।';

  @override
  String get busEdit => 'এডিট';

  @override
  String get busSetupTitle => 'রুটটি সাজানো শেষ করো';

  @override
  String get busSetupBody =>
      'স্টপ আর ছাড়ার সময় যোগ করলেই শিক্ষার্থীরা রুটটি ব্যবহার করতে পারবে।';

  @override
  String get busSetupStops => 'স্টপগুলো যোগ করো';

  @override
  String get busSetupTimes => 'ছাড়ার সময় যোগ করো';

  @override
  String get busSetupMap => 'স্টপগুলো ম্যাপে বসাও';

  @override
  String get busStart => 'শুরু';

  @override
  String busLegFrom(String stop) {
    return '$stop থেকে কত মিনিট';
  }

  @override
  String busLegBackFrom(String stop) {
    return 'ফেরার পথে: $stop থেকে কত মিনিট';
  }

  @override
  String get busFirstStopNote => 'ক্যাম্পাসে যাওয়ার যাত্রা এখান থেকে শুরু।';

  @override
  String get busLastStopNote => 'ফেরার যাত্রা এখান থেকে শুরু।';

  @override
  String get busNoTime => 'সময় নেই';

  @override
  String busLegValue(int minutes) {
    return '+$minutes মিনিট';
  }

  @override
  String busTotalTrip(int minutes) {
    return 'ক্যাম্পাসে $minutes মিনিট';
  }

  @override
  String get busLegHint =>
      'না জানলে খালি রাখো। শিক্ষার্থীরা তখন এই স্টপে “—” দেখবে।';

  @override
  String get busSameWayBack => 'ফেরার পথেও একই সময়';

  @override
  String get busSameWayBackHint =>
      'ফেরার পথে স্টপগুলোর মাঝে একই সময় লাগে, উল্টো দিকে।';

  @override
  String get busQuickAddHint => 'স্টপের নাম লিখে Enter চাপো';

  @override
  String get busPasteList => 'তালিকা পেস্ট করো';

  @override
  String get busPasteTitle => 'স্টপ পেস্ট করো';

  @override
  String get busPasteBody =>
      'প্রতি লাইনে একটা, বা কমা দিয়ে আলাদা করে, যেমন পরিবহন নোটিশে থাকে। বন্ধনীর লেখা চেনার জায়গা হবে।';

  @override
  String get busPasteFromClipboard => 'পেস্ট';

  @override
  String busPasteAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি স্টপ যোগ করো',
    );
    return '$_temp0';
  }

  @override
  String get busPasteNone => 'এই লেখায় এখনো কোনো স্টপ পাওয়া যায়নি।';

  @override
  String busTooManyStops(int max) {
    return 'একটা রুটে সর্বোচ্চ $maxটি স্টপ থাকতে পারে।';
  }

  @override
  String busStopRemoved(String name) {
    return '$name সরানো হয়েছে';
  }

  @override
  String get busDepartureRemoved => 'ছাড়ার সময় সরানো হয়েছে';

  @override
  String get busUndo => 'ফিরিয়ে আনো';

  @override
  String get busRemoveStop => 'স্টপ সরাও';

  @override
  String get busEditStop => 'স্টপ এডিট করো';

  @override
  String get busDiscardTitle => 'পরিবর্তনগুলো বাদ দেবে?';

  @override
  String get busDiscardBody => 'এগুলো এখনো সংরক্ষণ করা হয়নি।';

  @override
  String get busDiscard => 'বাদ দাও';

  @override
  String get busKeepEditing => 'এডিট চালিয়ে যাও';

  @override
  String get busTripTooLong =>
      'একটা যাত্রা ১০ ঘণ্টার বেশি হতে পারে না। মিনিটগুলো দেখে নাও।';

  @override
  String get busLocationNone => 'এখনো ম্যাপে নেই';

  @override
  String get busLocationSet => 'ম্যাপে আছে';

  @override
  String get busSetOnMap => 'ম্যাপে বসাও';

  @override
  String get busChangeLocation => 'বদলাও';

  @override
  String get busRemoveLocation => 'ম্যাপ থেকে সরাও';

  @override
  String busPickerTitle(String stop) {
    return '$stop বসাও';
  }

  @override
  String get busPickerHint => 'পিনটি স্টপের ওপর না আসা পর্যন্ত ম্যাপ সরাও।';

  @override
  String get busUseThisPlace => 'এই জায়গাটা নাও';

  @override
  String get busSearchPlace => 'জায়গা খোঁজো';

  @override
  String get busSearchNoResults =>
      'কোনো জায়গা পাওয়া যায়নি। অন্য নাম দিয়ে খোঁজো, বা ম্যাপ সরাও।';

  @override
  String get busSearchFailed => 'এখন খোঁজা যাচ্ছে না। ম্যাপ সরিয়ে বসাও।';

  @override
  String get busMapTitle => 'রুটের ম্যাপ';

  @override
  String get busOpenMap => 'ম্যাপ খোলো';

  @override
  String busNotOnMap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি স্টপ এখনো ম্যাপে নেই',
    );
    return '$_temp0';
  }

  @override
  String get busDirections => 'পথ দেখাও';

  @override
  String get busSetMyStop => 'আমার স্টপ করো';

  @override
  String busStopNoTime(String stop) {
    return '$stop-এর সময় দেওয়া নেই।';
  }

  @override
  String busRouteLeaves(String stop, String time) {
    return 'বাস $stop থেকে $time-এ ছাড়ে।';
  }

  @override
  String get busNoTripsToCampus => 'এই রুটে ক্যাম্পাসে যাওয়ার কোনো বাস নেই।';

  @override
  String get busNoTripsFromCampus =>
      'এই রুটে ক্যাম্পাস থেকে ফেরার কোনো বাস নেই।';

  @override
  String busLeavesFrom(String stop) {
    return '$stop থেকে কখন ছাড়ে';
  }

  @override
  String get busAddTimes => 'সময় যোগ করো';

  @override
  String get busAddAnotherTime => 'আরেকটা সময়';

  @override
  String busAddDepartures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ছাড়ার সময় যোগ করো',
    );
    return '$_temp0';
  }

  @override
  String get busPickTime => 'অন্তত একটা সময় দাও।';

  @override
  String busStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি স্টপ',
    );
    return '$_temp0';
  }

  @override
  String get busTimetableTitle => 'সময়সূচি';

  @override
  String get busNoTimesYet => 'এখনো সময় দেওয়া হয়নি';

  @override
  String busDistanceM(int metres) {
    return '$metres মিটার';
  }

  @override
  String busDistanceKm(String km) {
    return '$km কিমি';
  }

  @override
  String get busWhereAmI => 'আমি কোথায়';

  @override
  String busNearestStop(String stop, String distance) {
    return 'সবচেয়ে কাছের স্টপ: $stop, $distance দূরে';
  }

  @override
  String get busLocationServiceOff =>
      'এই ফোনে লোকেশন বন্ধ। তুমি কোথায় দেখতে লোকেশন চালু করো।';

  @override
  String get busLocationDenied =>
      'ভার্সিটি কথা তোমার লোকেশন ব্যবহার করতে পারছে না। সেটিংসে অনুমতি দিতে পারো।';

  @override
  String get busOpenSettings => 'সেটিংস';

  @override
  String get busFitRoute => 'পুরো রুট';

  @override
  String get busLocationPrivate => 'তোমার লোকেশন শুধু তোমার ফোনেই থাকে।';

  @override
  String get busUseMyLocation => 'আমার লোকেশন';

  @override
  String get busFindingYou => 'তোমাকে খোঁজা হচ্ছে…';

  @override
  String get busDriver => 'চালক';

  @override
  String get busDriverName => 'চালকের নাম (ঐচ্ছিক)';

  @override
  String get busDriverPhone => 'চালকের ফোন (ঐচ্ছিক)';

  @override
  String get busDriverPhoneHint => 'যেমন: 01712345678';

  @override
  String get busCallDriver => 'চালককে কল করো';

  @override
  String busCallName(String name) {
    return '$name-কে কল করো';
  }

  @override
  String get busPhoneInvalid => '01712345678-এর মতো ফোন নম্বর দাও।';

  @override
  String get teacherReviewsTitle => 'শিক্ষক মূল্যায়ন';

  @override
  String get teacherReviewsBody =>
      'নাম গোপন রেখে কোর্স আর পড়ানো রেট করো, যাতে সহপাঠীরা বেছে নিতে পারে আর শিক্ষকরা আরও ভালো করতে পারেন।';

  @override
  String get rankingsTitle => 'বিশ্ববিদ্যালয় র‍্যাংকিং';

  @override
  String get rankingsBody =>
      'শিক্ষার্থীদের রেটিংয়ে বিশ্ববিদ্যালয়গুলোর তুলনা: পড়াশোনা, সুবিধা, ক্যাম্পাস জীবন আর সমস্যা কত দ্রুত সমাধান হয়।';

  @override
  String get visitCampusTitle => 'অন্য ক্যাম্পাস ঘুরে দেখো';

  @override
  String get visitCampusBody =>
      'অন্য বিশ্ববিদ্যালয়গুলো ঘুরে দেখো: তাদের ক্যাম্পাস, ক্লাব, ইভেন্ট আর শিক্ষার্থীরা কী নিয়ে কথা বলছে।';

  @override
  String get gotIt => 'বুঝেছি';

  @override
  String get comingSoonNote => 'আমরা এটা বানাচ্ছি। সামনের কোনো আপডেটে আসবে।';

  @override
  String get cgpaTitle => 'সিজিপিএ ক্যালকুলেটর';

  @override
  String get cgpaHint => 'জিপিএ, সিজিপিএ আর লক্ষ্য';

  @override
  String get cgpaLabel => 'সিজিপিএ';

  @override
  String cgpaGpa(String gpa) {
    return 'জিপিএ $gpa';
  }

  @override
  String cgpaCredits(String credits) {
    return '$credits ক্রেডিট';
  }

  @override
  String get cgpaCreditsEarned => 'অর্জিত ক্রেডিট';

  @override
  String get cgpaLastSemester => 'গত সেমিস্টার';

  @override
  String get cgpaScaleUgc => 'ইউজিসি স্কেল';

  @override
  String get cgpaScaleCustom => 'নিজস্ব স্কেল';

  @override
  String get cgpaNoGrades => 'এখনো গ্রেড নেই';

  @override
  String cgpaCoursesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি কোর্স';
  }

  @override
  String get cgpaSemesters => 'সেমিস্টার';

  @override
  String get cgpaAddSemester => 'সেমিস্টার যোগ করো';

  @override
  String get cgpaSemesterName => 'সেমিস্টারের নাম';

  @override
  String get cgpaSemesterHint => 'যেমন: Spring 2026';

  @override
  String get cgpaRename => 'নাম বদলাও';

  @override
  String get cgpaMoveUp => 'উপরে নাও';

  @override
  String get cgpaMoveDown => 'নিচে নাও';

  @override
  String get cgpaDeleteSemesterTitle => 'এই সেমিস্টার আর এর কোর্সগুলো মুছবে?';

  @override
  String get cgpaEmptyTitle => 'তোমার সিজিপিএ হিসাব রাখো';

  @override
  String get cgpaEmptyBody => 'সেমিস্টার আর গ্রেড যোগ করো। সব এই ফোনেই থাকে।';

  @override
  String get cgpaAddCourse => 'কোর্স যোগ করো';

  @override
  String get cgpaEditCourse => 'কোর্স এডিট করো';

  @override
  String get cgpaCourseCode => 'কোর্স কোড';

  @override
  String get cgpaCourseTitle => 'কোর্সের নাম (ঐচ্ছিক)';

  @override
  String get cgpaCreditsLabel => 'ক্রেডিট';

  @override
  String get cgpaCreditsInvalid => 'ক্রেডিট ০.৫ থেকে ৬ এর মধ্যে হতে হবে।';

  @override
  String get cgpaCodeRequired => 'কোর্স কোড বা নাম লেখো।';

  @override
  String get cgpaGradeLetter => 'লেটার গ্রেড';

  @override
  String get cgpaGradeMarks => 'নম্বর';

  @override
  String get cgpaNotGraded => 'এখনো গ্রেড হয়নি';

  @override
  String get cgpaMarksLabel => '১০০-র মধ্যে নম্বর';

  @override
  String cgpaMarksGives(String letter, String points) {
    return 'গ্রেড: $letter ($points)';
  }

  @override
  String get cgpaMarksInvalid => 'নম্বর ০ থেকে ১০০ হতে হবে।';

  @override
  String get cgpaNotCounted => 'গোনা হয়নি: রিটেক';

  @override
  String get cgpaFromRoutine => 'রুটিনের কোর্সগুলো যোগ করো';

  @override
  String get cgpaFromRoutineHint =>
      'তোমার এখনকার কোর্সগুলো, গ্রেড দেওয়ার জন্য তৈরি।';

  @override
  String get cgpaTarget => 'লক্ষ্য ঠিক করো';

  @override
  String get cgpaTargetCgpa => 'লক্ষ্য সিজিপিএ';

  @override
  String get cgpaNextCredits => 'আর কত ক্রেডিট বাকি';

  @override
  String cgpaTargetNeeds(String gpa) {
    return 'ওই ক্রেডিটগুলোতে তোমার জিপিএ $gpa লাগবে।';
  }

  @override
  String get cgpaTargetReached =>
      'তুমি ইতিমধ্যে সেখানে আছো। পাস করতে থাকলেই থাকবে।';

  @override
  String cgpaTargetOut(String gpa) {
    return 'সম্ভব নয়: জিপিএ $gpa লাগবে। আরও ক্রেডিট বা কম লক্ষ্য দিয়ে দেখো।';
  }

  @override
  String get cgpaTargetInvalid => 'লক্ষ্য সিজিপিএ আর বাকি ক্রেডিট লেখো।';

  @override
  String get cgpaGradingScale => 'গ্রেডিং স্কেল';

  @override
  String get cgpaUseUgc => 'ইউজিসি অভিন্ন স্কেল (৪.০০)';

  @override
  String get cgpaUseUgcHint =>
      'বাংলাদেশের বেশিরভাগ বিশ্ববিদ্যালয় এটা ব্যবহার করে।';

  @override
  String get cgpaUseCustom => 'আমার বিশ্ববিদ্যালয়ের নিজস্ব স্কেল';

  @override
  String get cgpaUseCustomHint => 'নিজের গ্রেড, পয়েন্ট আর নম্বরের সীমা দাও।';

  @override
  String get cgpaGradeShort => 'গ্রেড';

  @override
  String get cgpaPoints => 'পয়েন্ট';

  @override
  String get cgpaMinMarks => 'যত নম্বর থেকে';

  @override
  String get cgpaAddGrade => 'গ্রেড যোগ করো';

  @override
  String get cgpaRetakeRule => 'রিটেক করা কোর্স';

  @override
  String get cgpaRetakeBest => 'সেরা চেষ্টা গোনা হবে';

  @override
  String get cgpaRetakeBestHint =>
      'সাধারণ নিয়ম: ভালো গ্রেড আগেরটার জায়গা নেয়।';

  @override
  String get cgpaRetakeLatest => 'শেষ চেষ্টা গোনা হবে';

  @override
  String get cgpaRetakeAll => 'সব চেষ্টা গোনা হবে';

  @override
  String get cgpaRetakeHint => 'কোর্স কোড দিয়ে চেষ্টাগুলো মেলানো হয়।';

  @override
  String get cgpaProblemEmpty => 'অন্তত একটি গ্রেড যোগ করো।';

  @override
  String get cgpaProblemLetter => 'প্রতিটি গ্রেডের আলাদা নাম লাগবে।';

  @override
  String get cgpaProblemPoints => 'পয়েন্ট ০ থেকে ৫ হতে হবে।';

  @override
  String get cgpaProblemMarks =>
      'প্রতিটি গ্রেডের শুরুর নম্বর আলাদা হতে হবে, ০ থেকে ১০০।';

  @override
  String get cgpaProblemZero => 'একটি গ্রেড ০ নম্বর থেকে শুরু হতে হবে।';

  @override
  String get cgpaProblemOrder => 'বেশি নম্বরে কম পয়েন্ট হতে পারে না।';

  @override
  String get cgpaClearAll => 'সব মুছে ফেলো';

  @override
  String get cgpaClearTitle => 'এই ফোনের সব সেমিস্টার আর গ্রেড মুছবে?';

  @override
  String get cgpaSave => 'সেভ করো';

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
  String get deleteAccountUnderstand => 'আমি বুঝেছি, এটি আর ফেরানো যাবে না';

  @override
  String get photoAdd => 'ছবি যোগ করো';

  @override
  String get photoChange => 'ছবি বদলাও';

  @override
  String get photoCrop => 'ছবি কাটো';

  @override
  String get photoTake => 'ছবি তোলো';

  @override
  String get photoGallery => 'গ্যালারি থেকে বেছে নাও';

  @override
  String get photoRemove => 'ছবি সরাও';

  @override
  String get photoUpdated => 'ছবি হালনাগাদ হয়েছে';

  @override
  String get photoRemoved => 'ছবি সরানো হয়েছে';

  @override
  String get photoNotAllowed => 'এই ছবিটি ব্যবহার করা যাবে না। অন্য একটা দাও।';

  @override
  String get photoCheckDown =>
      'এখন ছবি যাচাই করা যাচ্ছে না। পরে আবার চেষ্টা করো।';

  @override
  String get photoTooLarge => 'ছবিটি অনেক বড়।';

  @override
  String get photoInvalid => 'এই ফাইলটি ব্যবহারযোগ্য ছবি নয়।';

  @override
  String get photoWhoSees =>
      'তোমার ক্লাস গ্রুপের সহপাঠীরা তোমার ছবি দেখে। ক্যাম্পাস ভয়েসে কখনো দেখায় না।';

  @override
  String get photoGoogleHint =>
      'নিজের ছবি দেওয়া পর্যন্ত তোমার Google ছবি দেখাবে।';

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
  String get findClass => 'তোমার ক্লাস খুঁজে নাও';

  @override
  String get findClassHint => 'বিভাগ, ব্যাচ, কোর্স কোড বা শিক্ষক';

  @override
  String get findClassIntro =>
      'তোমার বিশ্ববিদ্যালয়ের ক্লাস রুটিন খোঁজো। পুরো সেকশনে যোগ দাও, বা শুধু তোমার কোর্সগুলো নাও।';

  @override
  String get findClassEmptyTitle => 'কোনো ক্লাস পাওয়া যায়নি';

  @override
  String get findClassEmptyBody =>
      'কোর্স কোড (CSE 311), বা বিভাগ আর ব্যাচ দিয়ে খোঁজো। অথবা সিআরের কাছে যোগদানের কোড চাও।';

  @override
  String get findClassOffline => 'খুঁজতে ইন্টারনেট সংযোগ লাগবে।';

  @override
  String get findClassJoined => 'যুক্ত আছ';

  @override
  String findClassCr(String name) {
    return 'সিআর: $name';
  }

  @override
  String get findClassMore => 'আরও দেখাও';

  @override
  String get findClassHaveCode => 'যোগদানের কোড আছে?';

  @override
  String get previewPickHint =>
      'যে কোর্সগুলো তুমি নাও না, সেগুলোর টিক তুলে দাও। শুধু রাখা কোর্সগুলোই দেখবে।';

  @override
  String get previewNoClasses => 'এই রুটিনে এখনো কোনো ক্লাস নেই।';

  @override
  String get joinWholeSection => 'পুরো সেকশনে যোগ দাও';

  @override
  String addSelectedCourses(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি কোর্স যোগ করো';
  }

  @override
  String get saveMyCourses => 'আমার কোর্স সংরক্ষণ করো';

  @override
  String get addedToRoutine => 'তোমার রুটিনে যোগ হয়েছে';

  @override
  String get similarGroupsTitle => 'এই ক্লাসটি হয়তো আগেই আছে';

  @override
  String get similarGroupsBody =>
      'নতুন না বানিয়ে এতে যোগ দাও, যাতে তোমার ক্লাসের রুটিন একটাই থাকে।';

  @override
  String get joinInstead => 'এতে যোগ দাও';

  @override
  String findableTitle(String university) {
    return '$university-এ খুঁজে পাওয়া যাবে';
  }

  @override
  String get findableBody =>
      'তোমার বিশ্ববিদ্যালয়ের শিক্ষার্থীরা খুঁজে এই ক্লাসটি পাবে। বন্ধ থাকলে: শুধু যোগদানের কোড দিয়ে যোগ দেওয়া যাবে।';

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
  String get shareInvite => 'আমন্ত্রণ শেয়ার করো';

  @override
  String get inviteCopied => 'আমন্ত্রণ কপি হয়েছে। ক্লাস গ্রুপে পেস্ট করো।';

  @override
  String inviteMessage(String group, String app, String link, String code) {
    return '$app-এ $group গ্রুপে যোগ দাও: $link\nঅথবা অ্যাপ খুলে \"কোড দিয়ে যোগ দাও\" চেপে $code লেখো';
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
  String get voiceActorSystem => 'ভার্সিটি কথা';

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
  String get voicePostNamedHint => 'এই পোস্টে শিক্ষার্থীরা তোমার নাম দেখবে।';

  @override
  String get voiceHowAnonymity => 'বেনামি কীভাবে কাজ করে';

  @override
  String get voicePost => 'পোস্ট করো';

  @override
  String get voiceNext => 'পরের ধাপ';

  @override
  String get voiceBack => 'আগের ধাপ';

  @override
  String get voicePosted => 'পোস্ট হয়েছে';

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

  @override
  String get campusTitle => 'ক্যাম্পাস';

  @override
  String get campusPrompt => 'ক্যাম্পাসে কী হচ্ছে?';

  @override
  String get campusTabForYou => 'তোমার জন্য';

  @override
  String get campusTabLatest => 'নতুন';

  @override
  String get campusTabAsk => 'প্রশ্নোত্তর';

  @override
  String get campusTabIssues => 'ইস্যু';

  @override
  String get campusIssuesOpen => 'চলমান';

  @override
  String get campusKindPost => 'পোস্ট';

  @override
  String get campusKindQuestion => 'প্রশ্ন';

  @override
  String get campusKindPoll => 'পোল';

  @override
  String get campusKindIssue => 'ইস্যু';

  @override
  String get campusBadgeQuestion => 'প্রশ্ন';

  @override
  String get campusBadgePoll => 'পোল';

  @override
  String get campusQuickPhoto => 'ছবি';

  @override
  String get voiceCatGeneral => 'সাধারণ';

  @override
  String get voiceCatEvent => 'ইভেন্ট';

  @override
  String get voiceCatLostFound => 'হারানো-পাওয়া';

  @override
  String get voiceCatBuySell => 'কেনাবেচা';

  @override
  String get voiceCatFun => 'মজা';

  @override
  String get reactLike => 'লাইক';

  @override
  String get reactHaha => 'হাহা';

  @override
  String get reactWow => 'ওয়াও';

  @override
  String get reactSad => 'দুঃখ';

  @override
  String get reactClap => 'সাবাস';

  @override
  String get campusComment => 'মন্তব্য';

  @override
  String get campusAnswer => 'উত্তর';

  @override
  String get campusShare => 'শেয়ার';

  @override
  String get campusSeeMore => 'আরও দেখো';

  @override
  String campusCommentCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি মন্তব্য';
  }

  @override
  String campusAnswerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি উত্তর';
  }

  @override
  String campusReactSemantics(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'রিঅ্যাক্ট করো। $countStringটি রিঅ্যাকশন';
  }

  @override
  String campusLikeSemantics(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'লাইক। $countStringটি লাইক';
  }

  @override
  String campusPollVotes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ভোট';
  }

  @override
  String campusPollDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'আর $countString দিন';
  }

  @override
  String campusPollHoursLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'আর $countString ঘণ্টা';
  }

  @override
  String get campusPollEndingSoon => 'শিগগিরই শেষ';

  @override
  String get campusPollFinal => 'চূড়ান্ত ফলাফল';

  @override
  String get campusPollVoteToSee => 'ফলাফল দেখতে ভোট দাও';

  @override
  String get campusReply => 'উত্তর দাও';

  @override
  String campusReplyingTo(String name) {
    return '$name-কে উত্তর দিচ্ছ';
  }

  @override
  String campusViewReplies(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি উত্তর দেখো';
  }

  @override
  String get campusHideReplies => 'উত্তর লুকাও';

  @override
  String get campusReplyHint => 'উত্তর লেখো…';

  @override
  String get campusAnswerHint => 'তোমার উত্তর লেখো…';

  @override
  String get campusNewPost => 'নতুন পোস্ট';

  @override
  String get campusCreateTitle => 'পোস্ট তৈরি করো';

  @override
  String get campusPostAction => 'পোস্ট করো';

  @override
  String get campusPostHint => 'কী ভাবছ?';

  @override
  String get campusQuestionHint => 'ক্যাম্পাসকে যেকোনো কিছু জিজ্ঞেস করো…';

  @override
  String get campusPollHint => 'প্রশ্নটি লেখো…';

  @override
  String campusPollOption(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'অপশন $nString';
  }

  @override
  String get campusPollAddOption => 'অপশন যোগ করো';

  @override
  String get campusPollLength => 'পোল চলবে';

  @override
  String campusPollDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString দিন';
  }

  @override
  String get campusPostingAs => 'পোস্ট করছ';

  @override
  String get campusTopic => 'বিষয়';

  @override
  String get campusIssueNote =>
      'ইস্যু তোমার বিশ্ববিদ্যালয়ের কর্মকর্তাদের কাছে যায়; তাঁরা উত্তর দিতে আর অবস্থা জানাতে পারেন।';

  @override
  String campusShareText(String text, String link) {
    return '$text\n\nভার্সিটিকথায় দেখো: $link';
  }

  @override
  String get campusMyPosts => 'আমার পোস্ট';

  @override
  String get campusEmptyFeed => 'এখানে এখনো কিছু নেই';

  @override
  String get campusEmptyFeedHint =>
      'আলাপ শুরু করো: কিছু শেয়ার করো বা প্রশ্ন করো।';

  @override
  String get campusEmptyAsk => 'এখনো কোনো প্রশ্ন নেই';

  @override
  String get campusEmptyAskHint =>
      'যেকোনো কিছু জিজ্ঞেস করো: এখানকার সিনিয়র আর সহপাঠীরা উত্তর দিতে পারে।';

  @override
  String get campusEmptyMine => 'তুমি এখনো কিছু পোস্ট করোনি';

  @override
  String get campusEmptyMineHint =>
      'তোমার পোস্ট, প্রশ্ন, পোল আর ইস্যু এখানে দেখাবে।';

  @override
  String get campusEmptySearch => 'এই খোঁজার সাথে কিছু মেলেনি';

  @override
  String get campusSearchHint => 'ক্যাম্পাসে খোঁজো';

  @override
  String get campusDeletePostTitle => 'পোস্টটি মুছে ফেলবে?';

  @override
  String get campusEditPost => 'পোস্ট সম্পাদনা';

  @override
  String get campusTextLabel => 'লেখা';

  @override
  String get campusPhotoOrText => 'কিছু লেখো বা একটি ছবি যোগ করো।';

  @override
  String get campusPollNeedsOptions => 'অন্তত দুটি আলাদা অপশন দাও।';

  @override
  String get campusQuestionTooShort => 'প্রশ্নটি আরেকটু বিস্তারিত লেখো।';

  @override
  String get errorPollClosed => 'এই পোলটি শেষ হয়ে গেছে।';

  @override
  String get errorAlreadyVoted => 'তুমি এই পোলে আগেই ভোট দিয়েছ।';

  @override
  String get errorNotAnIssue => 'এটা শুধু ইস্যুতে করা যায়।';

  @override
  String get editAnnouncement => 'ঘোষণা সম্পাদনা করো';

  @override
  String get editedLabel => 'সম্পাদিত';

  @override
  String get announcementSaved => 'সংরক্ষণ হয়েছে। সহপাঠীরা নতুন লেখাটি দেখবে।';

  @override
  String get saveAction => 'সংরক্ষণ করো';

  @override
  String get openLinkFailed => 'লিংকটি খোলা গেল না।';

  @override
  String get showLess => 'কম দেখাও';

  @override
  String get courseLinks => 'কোর্সের লিংক';

  @override
  String get courseLinksAdd => 'চ্যাট গ্রুপ, ক্লাসরুম কোড… যোগ করো';

  @override
  String get courseLinksEdit => 'কোর্সের লিংক সম্পাদনা';

  @override
  String get courseLinksOptional => 'সবই ঐচ্ছিক। গ্রুপের সবাই এগুলো দেখবে।';

  @override
  String get courseLinksSaved =>
      'সংরক্ষণ হয়েছে। সহপাঠীরা ক্লাসের বিবরণে দেখবে।';

  @override
  String get courseChat => 'ক্লাসের চ্যাট গ্রুপ';

  @override
  String get courseChatHint => 'chat.whatsapp.com/… বা m.me/j/…';

  @override
  String get courseClassroom => 'গুগল ক্লাসরুম';

  @override
  String get courseClassroomCode => 'ক্লাসরুম কোড';

  @override
  String get courseClassroomCodeHint => 'যেমন ab3x9kq';

  @override
  String get courseOpenClassroom => 'ক্লাসরুম খোলো';

  @override
  String get courseMaterials => 'কোর্সের ম্যাটেরিয়াল';

  @override
  String get courseMaterialsHint => 'drive.google.com/…';

  @override
  String get courseTeacherEmail => 'শিক্ষকের ইমেইল';

  @override
  String get courseNotes => 'নোট';

  @override
  String get courseNotesHint =>
      'অফিস আওয়ার, অ্যাসাইনমেন্ট কীভাবে জমা দিতে হয়…';

  @override
  String get courseLinkInvalid =>
      'একটি ওয়েব লিংক দাও, যেমন chat.whatsapp.com/…';

  @override
  String get courseEmailInvalid => 'একটি ইমেইল ঠিকানা দাও।';

  @override
  String get courseCodeInvalid => 'শুধু অক্ষর ও সংখ্যা (৩–২০টি)।';

  @override
  String courseClassroomChip(String code) {
    return 'ক্লাসরুম: $code';
  }

  @override
  String get courseMaterialsShort => 'ম্যাটেরিয়াল';

  @override
  String get courseCopied => 'কপি হয়েছে';

  @override
  String get bloodTitle => 'রক্তদান';

  @override
  String get bloodHint => 'দ্রুত রক্তদাতা খুঁজো, বা কারও পাশে দাঁড়াও।';

  @override
  String get bloodBecomeDonor => 'রক্তদাতা হও';

  @override
  String get bloodBecomeDonorHint =>
      'তোমার বিশ্ববিদ্যালয়ে কারও তোমার গ্রুপের রক্ত লাগলে তুমি নোটিফিকেশন পাবে।';

  @override
  String get bloodYourGroup => 'তোমার রক্তের গ্রুপ';

  @override
  String get bloodAvailable => 'রক্ত দিতে প্রস্তুত';

  @override
  String get bloodAvailableHint => 'তোমার গ্রুপের অনুরোধ এলে নোটিফিকেশন পাবে।';

  @override
  String get bloodCanDonateNow => 'তুমি এখন রক্ত দিতে পারবে';

  @override
  String bloodCanDonateFrom(String date) {
    return 'আবার রক্ত দিতে পারবে $date থেকে';
  }

  @override
  String bloodDonationsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString বার রক্ত দিয়েছ',
      zero: 'এখনো রক্ত দেওয়া হয়নি',
    );
    return '$_temp0';
  }

  @override
  String get bloodIDonated => 'আজ রক্ত দিয়েছি';

  @override
  String get bloodDonatedThanks =>
      'ধন্যবাদ! তুমি একটি জীবন বাঁচাতে সাহায্য করেছ।';

  @override
  String get bloodEditDonor => 'রক্তদাতা প্রোফাইল সম্পাদনা';

  @override
  String get bloodLeaveDonors => 'রক্তদাতা থেকে সরে যাও';

  @override
  String get bloodLeaveDonorsConfirm =>
      'তুমি আর রক্তের অনুরোধ পাবে না। চাইলে যেকোনো সময় আবার যোগ দিতে পারবে।';

  @override
  String get bloodLastDonated => 'শেষ রক্তদান';

  @override
  String get bloodNeverDonated => 'কখনো না, বা মনে নেই';

  @override
  String get bloodPhone => 'ফোন নম্বর';

  @override
  String get bloodPhoneHint =>
      'তুমি যাকে রক্ত দিতে চাইবে, শুধু তাকেই দেখানো হবে।';

  @override
  String get bloodPhoneInvalid => '০১৭১২৩৪৫৬৭৮-এর মতো মোবাইল নম্বর দাও।';

  @override
  String get bloodPrivacyNote =>
      'তোমার রক্তের গ্রুপ গোপন থাকবে: কেউ রক্তদাতার তালিকা দেখতে পারবে না।';

  @override
  String get bloodSaveDonor => 'সংরক্ষণ করো';

  @override
  String get bloodRequests => 'অনুরোধ';

  @override
  String get bloodMyRequests => 'আমার অনুরোধ';

  @override
  String get bloodMyGroupOnly => 'আমার গ্রুপ';

  @override
  String get bloodNoRequests => 'এই মুহূর্তে কারও রক্ত লাগবে না';

  @override
  String get bloodNoRequestsHint =>
      'তোমার বিশ্ববিদ্যালয়ে কারও লাগলে এখানে দেখাবে।';

  @override
  String get bloodNoMyRequests => 'তুমি এখনো রক্ত চাওনি';

  @override
  String get bloodRequestAction => 'রক্ত চাও';

  @override
  String get bloodUrgent => 'জরুরি';

  @override
  String bloodUnits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ব্যাগ';
  }

  @override
  String bloodNeededTitle(String group) {
    return '$group রক্ত প্রয়োজন';
  }

  @override
  String bloodToday(String time) {
    return 'আজ, $time';
  }

  @override
  String bloodTomorrow(String time) {
    return 'আগামীকাল, $time';
  }

  @override
  String get bloodStatusFulfilled => 'রক্ত পাওয়া গেছে';

  @override
  String get bloodStatusClosed => 'বাতিল';

  @override
  String get bloodStatusExpired => 'মেয়াদ শেষ';

  @override
  String bloodResponses(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString জন রক্ত দিতে পারবেন',
      zero: 'এখনো কেউ সাড়া দেননি',
    );
    return '$_temp0';
  }

  @override
  String bloodNotified(int count, String group) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString জন $group রক্তদাতাকে জানানো হয়েছে';
  }

  @override
  String bloodMatching(int count, String group) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'তোমার বিশ্ববিদ্যালয়ে $countString জন $group রক্তদাতা';
  }

  @override
  String bloodCompatible(String groups) {
    return 'যাদের রক্তও নেওয়া যাবে: $groups';
  }

  @override
  String get bloodContact => 'যোগাযোগ';

  @override
  String get bloodCall => 'কল করো';

  @override
  String get bloodPhoneCopied => 'নম্বর কপি হয়েছে';

  @override
  String get bloodICanDonate => 'আমি রক্ত দিতে পারব';

  @override
  String get bloodWithdraw => 'আর পারছি না';

  @override
  String get bloodYouOffered => 'তুমি রক্ত দিতে চেয়েছ';

  @override
  String get bloodRespondTitle => 'রক্ত দিতে চাও?';

  @override
  String bloodRespondBody(String name) {
    return 'তোমার নাম, রক্তের গ্রুপ ও ফোন নম্বর $name-এর কাছে যাবে; তিনি তোমাকে কল করবেন।';
  }

  @override
  String get bloodRespondSend => 'আমার নম্বর পাঠাও';

  @override
  String bloodResponded(String name) {
    return 'ধন্যবাদ! $name এখন তোমাকে কল করতে পারবেন।';
  }

  @override
  String bloodNotYourGroup(String group, String mine) {
    return 'এই অনুরোধে $group লাগবে; তোমার গ্রুপ $mine।';
  }

  @override
  String get bloodGotBlood => 'রক্ত পেয়েছি';

  @override
  String get bloodCancelRequest => 'অনুরোধ বাতিল করো';

  @override
  String get bloodCancelConfirm =>
      'অনুরোধটি বাতিল করবে? রক্তদাতারা আর এটি দেখবেন না।';

  @override
  String get bloodClosedThanks => 'সাহায্য পেয়েছ জেনে ভালো লাগল। ভালো থেকো!';

  @override
  String get bloodGroupNeeded => 'কোন গ্রুপের রক্ত লাগবে';

  @override
  String get bloodUnitsLabel => 'ব্যাগ';

  @override
  String get bloodHospital => 'হাসপাতাল';

  @override
  String get bloodHospitalHint => 'যেমন এনাম মেডিকেল কলেজ হাসপাতাল';

  @override
  String get bloodArea => 'এলাকা';

  @override
  String get bloodAreaHint => 'যেমন সাভার';

  @override
  String get bloodWhen => 'কখন';

  @override
  String get bloodWhenToday => 'আজ';

  @override
  String get bloodWhenTomorrow => 'আগামীকাল';

  @override
  String get bloodWhenPick => 'তারিখ বাছো';

  @override
  String get bloodUrgentHint => 'কয়েক ঘণ্টার মধ্যে লাগবে';

  @override
  String get bloodContactName => 'যোগাযোগের ব্যক্তি';

  @override
  String get bloodContactPhone => 'যোগাযোগের ফোন';

  @override
  String get bloodNote => 'নোট (ঐচ্ছিক)';

  @override
  String get bloodNoteHint => 'যেমন থ্যালাসেমিয়া রোগী, সকাল ১০টায় অপারেশন';

  @override
  String get bloodPost => 'অনুরোধ পাঠাও';

  @override
  String bloodPostedNone(String group) {
    return 'পোস্ট হয়েছে। শেয়ারও করো: এখানে এখনো কোনো $group রক্তদাতা যোগ দেননি।';
  }

  @override
  String get bloodVerifyFirst =>
      'রক্ত চাইতে তোমার বিশ্ববিদ্যালয়ের ইমেইল যাচাই করো। এতে অনুরোধগুলো সত্যি থাকে।';

  @override
  String bloodShareIntro(String group) {
    return '🩸 $group রক্ত প্রয়োজন';
  }

  @override
  String bloodShareVia(String link) {
    return 'ভার্সিটিকথায় দেখো: $link';
  }

  @override
  String get errorVerifyRequired =>
      'আগে তোমার বিশ্ববিদ্যালয়ের ইমেইল যাচাই করো।';

  @override
  String get errorTooManyOpenRequests =>
      'তোমার ৩টি অনুরোধ খোলা আছে। আগে একটি বন্ধ করো।';

  @override
  String get errorBloodRequestNotFound => 'এই অনুরোধটি আর নেই।';

  @override
  String get errorRequestClosed => 'এই অনুরোধটি বন্ধ হয়ে গেছে।';

  @override
  String get errorCannotRespondOwn => 'এটি তোমার নিজের অনুরোধ।';

  @override
  String get errorDonorRequired => 'আগে তোমার রক্তদাতা প্রোফাইল তৈরি করো।';

  @override
  String get visitSearchHint => 'বিশ্ববিদ্যালয় খুঁজো';

  @override
  String get visitMostActive => 'এই সপ্তাহে সবচেয়ে সক্রিয়';

  @override
  String visitStudents(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString জন শিক্ষার্থী';
  }

  @override
  String visitPostsWeek(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই সপ্তাহে $countStringটি পোস্ট',
      zero: 'এই সপ্তাহে পোস্ট নেই',
    );
    return '$_temp0';
  }

  @override
  String get visitClassGroups => 'ক্লাস গ্রুপ';

  @override
  String get visitBusRoutes => 'বাস রুট';

  @override
  String get visitStudentsLabel => 'শিক্ষার্থী';

  @override
  String get visitPostsLabel => 'এই সপ্তাহের পোস্ট';

  @override
  String get visitPublic => 'সরকারি';

  @override
  String get visitPrivate => 'বেসরকারি';

  @override
  String get visitWebsite => 'ওয়েবসাইট';

  @override
  String visitYouAreVisiting(String name) {
    return 'তুমি $name ঘুরে দেখছ। শুধু এর শিক্ষার্থীরা মন্তব্য করতে পারে।';
  }

  @override
  String get visitEmpty => 'এখানে এখনো কোনো পোস্ট নেই';

  @override
  String get visitEmptyHint => 'এর শিক্ষার্থীরা এখনো কিছু পোস্ট করেনি।';

  @override
  String get visitNoCampuses => 'কোনো বিশ্ববিদ্যালয় মেলেনি';

  @override
  String get visitYourCampus => 'তোমার ক্যাম্পাস';

  @override
  String get campusOnlyLabel => 'শুধু আমার বিশ্ববিদ্যালয়';

  @override
  String get campusOnlyOn =>
      'শুধু তোমার বিশ্ববিদ্যালয়ের শিক্ষার্থীরা দেখতে পারবে।';

  @override
  String get campusOnlyOff =>
      'সব বিশ্ববিদ্যালয়ের শিক্ষার্থীরা দেখতে পারবে (মন্তব্য করতে পারবে না)।';

  @override
  String get campusOnlyBadge => 'শুধু আমার বিশ্ববিদ্যালয়';

  @override
  String get voiceAnon9 =>
      '\"শুধু আমার বিশ্ববিদ্যালয়\" না বাছলে পোস্ট, প্রশ্ন ও পোল অন্য বিশ্ববিদ্যালয়ের শিক্ষার্থীরাও পড়তে পারে। ইস্যু ও নিরাপত্তা রিপোর্ট তোমার বিশ্ববিদ্যালয়ের ভেতরেই থাকে।';

  @override
  String get errorVisitorReadOnly =>
      'এটা শুধু এই বিশ্ববিদ্যালয়ের শিক্ষার্থীরা করতে পারে।';

  @override
  String get errorUniversityGone => 'এই বিশ্ববিদ্যালয়টি ভার্সিটিকথায় নেই।';

  @override
  String get visitReadOnlyNote =>
      'তুমি অন্য বিশ্ববিদ্যালয় ঘুরে দেখছ: পড়তে ও রিঅ্যাক্ট করতে পারো; মন্তব্য শুধু এর শিক্ষার্থীরা করতে পারে।';

  @override
  String get busLive => 'লাইভ';

  @override
  String busLiveSharing(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringজন শেয়ার করছে',
    );
    return '$_temp0';
  }

  @override
  String busLiveSecondsAgo(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString সেকেন্ড আগে';
  }

  @override
  String busLiveMinutesAgo(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট আগে';
  }

  @override
  String busLiveAt(String stop) {
    return '$stop-এ আছে';
  }

  @override
  String busLiveHeading(String stop) {
    return '$stop-এর পথে';
  }

  @override
  String busLiveNear(String stop) {
    return '$stop-এর কাছে';
  }

  @override
  String get busLiveOnTheWay => 'পথে আছে';

  @override
  String get busLiveOffRoute => 'স্বাভাবিক রুটের বাইরে';

  @override
  String busLiveLate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট দেরিতে';
  }

  @override
  String busLiveEarly(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট আগে চলছে';
  }

  @override
  String get busLiveOnTime => 'সময়মতো চলছে';

  @override
  String busLiveEta(String stop, int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '~$minutesString মিনিটে $stop-এ';
  }

  @override
  String busLiveEtaNow(String stop) {
    return 'এখনই $stop-এ পৌঁছাচ্ছে';
  }

  @override
  String busLivePassed(String stop) {
    return '$stop পার হয়ে গেছে';
  }

  @override
  String get busLiveMap => 'লাইভ ম্যাপ';

  @override
  String busLiveEtaShort(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '~$minutesString মিনিট';
  }

  @override
  String get busLiveNow => 'এখনই';

  @override
  String get busLiveBus => 'লাইভ বাস';

  @override
  String get busOffTimetable => 'সময়সূচির বাইরে';

  @override
  String busShareAsk(String time) {
    return '$time-এর বাসে আছো?';
  }

  @override
  String get busShareAskBody =>
      'বাসটা কোথায় আছে শেয়ার করো, যাতে স্টপে অপেক্ষায় থাকা সবাই দেখতে পায়।';

  @override
  String get busShareImOn => 'আমি এই বাসে আছি';

  @override
  String get busShareOn => 'বাসটা লাইভ শেয়ার করো';

  @override
  String get busSharingTitle => 'তুমি বাসটা লাইভ শেয়ার করছ';

  @override
  String busSharingOthers(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'তুমি আর আরও $countStringজন',
      zero: 'এখন পর্যন্ত শুধু তুমি',
    );
    return '$_temp0';
  }

  @override
  String get busSharingOffline =>
      'ইন্টারনেট নেই: লোকেশন জমা থাকছে, পরে পাঠানো হবে';

  @override
  String get busSharingStarting => 'শুরু হচ্ছে…';

  @override
  String get busSharingStop => 'শেয়ার বন্ধ করো';

  @override
  String get busShareWhich => 'তুমি কোন বাসে আছো?';

  @override
  String get busShareOther => 'অন্য বাস';

  @override
  String get busShareWhat =>
      'শেয়ার চলার সময় তোমার লোকেশন পাঠানো হয়, স্ক্রিন বন্ধ থাকলেও। বন্ধ হওয়া পর্যন্ত একটি নোটিফিকেশন থাকে।';

  @override
  String get busShareWho =>
      'এই রুটের শিক্ষার্থীরা শুধু বাসটা দেখে, কে শেয়ার করছে তা কখনো না।';

  @override
  String get busShareEnds =>
      'রুটের শেষে বা ৩ ঘণ্টা পর নিজেই বন্ধ হয়। লোকেশনগুলো এক দিন পর মুছে ফেলা হয়।';

  @override
  String get busShareStart => 'শেয়ার শুরু করো';

  @override
  String get busShareNotOnRoute =>
      'তুমি এই রুট থেকে দূরে আছো মনে হচ্ছে। বাসে উঠে শেয়ার শুরু করো।';

  @override
  String get busShareNotRunning =>
      'ওই বাস এখন চলছে না। যে বাসে আছো সেটা বেছে নাও।';

  @override
  String get busShareLimit => 'আজ অনেকবার শেয়ার করেছ। কাল আবার চেষ্টা করো।';

  @override
  String busShareNoticeTitle(String route) {
    return '$route লাইভ শেয়ার হচ্ছে';
  }

  @override
  String get busShareNoticeText =>
      'অপেক্ষায় থাকা শিক্ষার্থীরা বাসটা কোথায় দেখতে পাচ্ছে। বন্ধ করতে অ্যাপ খোলো।';

  @override
  String get busShareChannel => 'লাইভ বাস শেয়ার';

  @override
  String get busThanksTitle => 'শেয়ার করার জন্য ধন্যবাদ!';

  @override
  String busThanksHelped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringজন শিক্ষার্থী তোমার বাস দেখেছে।',
      zero: 'এই রুটের সবার জন্য তোমার বাস ম্যাপে ছিল।',
    );
    return '$_temp0';
  }

  @override
  String busThanksTrips(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এ পর্যন্ত $countStringটি ট্রিপ শেয়ার করেছ',
    );
    return '$_temp0';
  }

  @override
  String get busEndedArrived =>
      'বাস রুটের শেষে পৌঁছেছে, তাই শেয়ার বন্ধ হয়েছে।';

  @override
  String get busEndedOffRoute =>
      'তুমি রুট থেকে সরে গেছ, তাই শেয়ার বন্ধ হয়েছে।';

  @override
  String get busEndedExpired => 'অনেকক্ষণ পর শেয়ার বন্ধ হয়েছে।';

  @override
  String get busEndedReplaced => 'শেয়ার অন্য বাসে চলে গেছে।';

  @override
  String busFeedbackTitle(String time) {
    return '$time-এর বাস কেমন ছিল?';
  }

  @override
  String get busFeedbackTrip => 'ট্রিপ কেমন ছিল?';

  @override
  String busFeedbackAt(String stop, String time) {
    return '$stop, $time';
  }

  @override
  String get busFeedbackOnTime => 'সময়মতো';

  @override
  String get busFeedbackLate => 'দেরিতে';

  @override
  String get busFeedbackNoShow => 'আসেনি';

  @override
  String get busFeedbackCrowded => 'ভিড় ছিল';

  @override
  String get busFeedbackThanks => 'ধন্যবাদ! এতে রুটের সবার সুবিধা হয়।';

  @override
  String get busFeedbackNotNow => 'এখন না';

  @override
  String get busNoteOnTime => 'সাধারণত সময়মতো';

  @override
  String get busNoteLate => 'প্রায়ই দেরি করে';

  @override
  String busNoteLateMin(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'প্রায়ই ~$minutesString মিনিট দেরি করে';
  }

  @override
  String get busNoteCrowded => 'প্রায়ই ভিড় থাকে';

  @override
  String get busNoteNoShow => 'মাঝে মাঝে আসে না';

  @override
  String get busAlert => 'জানিয়ো';

  @override
  String busAlertOn(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'জানাবে: $minutesString মিনিট';
  }

  @override
  String get busAlertTitle => 'লাইভ বাস কতটা দূরে থাকলে জানাবে?';

  @override
  String busAlertMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'আমার স্টপ থেকে $minutesString মিনিট দূরে';
  }

  @override
  String get busAlertHint => 'বাসে কেউ লাইভ শেয়ার করলে কাজ করে।';

  @override
  String get busAlertOff => 'বন্ধ';

  @override
  String busAlertSaved(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'বাস $minutesString মিনিট দূরে এলে জানানো হবে।';
  }

  @override
  String get busShareJoin => 'আমিও আছি';

  @override
  String get verifyGetTitle => 'ভেরিফায়েড হও';

  @override
  String get verifyBannerTitle => 'তোমার বিশ্ববিদ্যালয়ে ভেরিফায়েড হও';

  @override
  String get verifyBannerBody =>
      'সিআর বা দুজন সহপাঠীকে বলো, অথবা বিশ্ববিদ্যালয়ের ইমেইল ব্যবহার করো।';

  @override
  String get verifyIntro => 'তোমার জন্য সহজ উপায়টা বেছে নাও।';

  @override
  String get verifyViaEmail => 'বিশ্ববিদ্যালয়ের ইমেইল ব্যবহার করো';

  @override
  String get verifyViaEmailHint => 'সেখানে একটি ৬ অঙ্কের কোড পাঠাব।';

  @override
  String get verifyAskCr => 'তোমার সিআরকে বলো';

  @override
  String get verifyAskCrHint =>
      'গ্রুপের সদস্য তালিকা থেকে তোমার সিআর তোমাকে কনফার্ম করতে পারবে।';

  @override
  String verifyCrLine(String name, String group) {
    return '$group-এর সিআর $name';
  }

  @override
  String get verifyNoCr =>
      'তুমি এখনো কোনো ক্লাস গ্রুপে নেই। আগে তোমার সেকশনের গ্রুপে যোগ দাও, তারপর সিআরকে বলো।';

  @override
  String get verifyAskClassmates => '২ জন সহপাঠীকে বলো';

  @override
  String get verifyAskClassmatesHint =>
      'তোমার বিশ্ববিদ্যালয়ের ভেরিফায়েড সহপাঠীরা একটি লিংক দিয়ে তোমার হয়ে নিশ্চিত করতে পারবে।';

  @override
  String verifyProgress(int count, int needed) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);

    return '$neededString জনের মধ্যে $countString জন';
  }

  @override
  String verifyVouchedBy(String names) {
    return '$names নিশ্চিত করেছে';
  }

  @override
  String get verifyShareLink => 'লিংক শেয়ার করো';

  @override
  String verifyShareText(String university, String link) {
    return 'হাই! ভার্সিটিকথায় নিশ্চিত করো যে আমি $university-এ পড়ি: $link';
  }

  @override
  String get verifyDoneTitle => 'তুমি এখন ভেরিফায়েড';

  @override
  String get verifiedViaEmail => 'বিশ্ববিদ্যালয়ের ইমেইল দিয়ে ভেরিফায়েড।';

  @override
  String get verifiedViaCr => 'তোমার সিআর কনফার্ম করেছে।';

  @override
  String get verifiedViaVouch => 'সহপাঠীরা নিশ্চিত করেছে।';

  @override
  String get verifiedViaCampusAdmin => 'ক্যাম্পাস অ্যাডমিন ভেরিফাই করেছে।';

  @override
  String get verifiedViaAdmin => 'ভার্সিটিকথা টিম ভেরিফাই করেছে।';

  @override
  String get vouchTitle => 'সহপাঠীর হয়ে নিশ্চিত করো';

  @override
  String vouchButton(String university) {
    return 'আমি ওকে চিনি, ও $university-এ পড়ে';
  }

  @override
  String get vouchCareHint => 'ওকে সত্যিই চিনলে তবেই নিশ্চিত করো।';

  @override
  String vouchProgress(int count, int needed) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);

    return '$neededString জনের মধ্যে $countString জন সহপাঠী নিশ্চিত করেছে';
  }

  @override
  String get vouchAlready => 'তুমি আগেই নিশ্চিত করেছ। ধন্যবাদ!';

  @override
  String vouchThanksMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'ধন্যবাদ! আরও $countString জন সহপাঠী দরকার';
  }

  @override
  String vouchNowVerified(String name) {
    return '$name এখন ভেরিফায়েড';
  }

  @override
  String get vouchReasonSelf =>
      'এটা তোমার নিজের লিংক। সহপাঠীদের পাঠাও, ওরা তোমার হয়ে নিশ্চিত করবে।';

  @override
  String get vouchReasonNotVerified =>
      'নিশ্চিত করার আগে তোমাকে নিজে ভেরিফায়েড হতে হবে। বিশ্ববিদ্যালয়ের ইমেইল ব্যবহার করো, অথবা সিআরকে বলো।';

  @override
  String get vouchReasonOther =>
      'শুধু নিজের বিশ্ববিদ্যালয়ের শিক্ষার্থীর হয়ে নিশ্চিত করা যায়।';

  @override
  String get vouchReasonBlocked =>
      'এখন তুমি অন্যের হয়ে নিশ্চিত করতে পারবে না। ক্যাম্পাস অ্যাডমিনকে জিজ্ঞেস করো।';

  @override
  String get vouchReasonLimit =>
      'সম্প্রতি অনেকবার নিশ্চিত করেছ (৩০ দিনে ৫ বার)। পরে আবার চেষ্টা করো।';

  @override
  String vouchReasonAlreadyVerified(String name) {
    return '$name আগেই ভেরিফায়েড।';
  }

  @override
  String get vouchNotFound => 'এই লিংকটি আর কাজ করছে না।';

  @override
  String get confirmAction => 'কনফার্ম';

  @override
  String confirmTitle(String name) {
    return '$name-কে কনফার্ম করবে?';
  }

  @override
  String get confirmBody =>
      'শুধু তাদেরই কনফার্ম করো, যাদের তুমি চেনো এবং যারা তোমার সেকশনের।';

  @override
  String confirmedSnack(String name) {
    return '$name এখন ভেরিফায়েড';
  }

  @override
  String get confirmLimit =>
      'সম্প্রতি অনেক শিক্ষার্থীকে কনফার্ম করেছ (৩০ দিনে ৮০ জন)। পরে আবার চেষ্টা করো।';

  @override
  String get confirmNotCr => 'শুধু এই গ্রুপের সিআর কনফার্ম করতে পারে।';

  @override
  String get requestUniversityAction =>
      'তোমার বিশ্ববিদ্যালয় যোগ করার অনুরোধ করো';

  @override
  String get requestUniversityTitle => 'বিশ্ববিদ্যালয় যোগ করার অনুরোধ';

  @override
  String get requestUniversityHint =>
      'তোমার বিশ্ববিদ্যালয়ের নাম জানাও, আমরা এর ইমেইল যোগ করব।';

  @override
  String get requestUniversityName => 'বিশ্ববিদ্যালয়ের নাম';

  @override
  String get requestUniversityPick => 'তালিকা থেকে বেছে নাও';

  @override
  String get requestUniversitySend => 'অনুরোধ পাঠাও';

  @override
  String get requestUniversityDone => 'আমরা শিগগিরই যোগ করব';

  @override
  String get requestUniversityDoneBody =>
      'ধন্যবাদ! ততদিন Google দিয়ে চালিয়ে যেতে পারো।';

  @override
  String get requestUniversityNeeded =>
      'বিশ্ববিদ্যালয়ের নাম লেখো, অথবা তালিকা থেকে বেছে নাও।';

  @override
  String requestUniversityEmail(String email) {
    return 'তোমার ইমেইল: $email';
  }

  @override
  String campusAdminEntry(String university) {
    return 'ক্যাম্পাস অ্যাডমিন · $university';
  }

  @override
  String get campusAdminTitle => 'ক্যাম্পাস অ্যাডমিন';

  @override
  String get caTabInbox => 'ইনবক্স';

  @override
  String get caTabStudents => 'শিক্ষার্থী';

  @override
  String get caTabSections => 'সেকশন';

  @override
  String get caTabBusReps => 'বাস প্রতিনিধি';

  @override
  String get caTabReports => 'রিপোর্ট';

  @override
  String get caTabBlood => 'রক্ত';

  @override
  String get caNotAdmin => 'তুমি ক্যাম্পাস অ্যাডমিন নও।';

  @override
  String get caWaiting => 'ভেরিফিকেশনের অপেক্ষায়';

  @override
  String get caWaitingEmpty => 'কেউ অপেক্ষায় নেই।';

  @override
  String caWaitingMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString জন শিক্ষার্থী অপেক্ষায়';
  }

  @override
  String get caNeedsAttention => 'নজর দরকার';

  @override
  String caReportsWaiting(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি রিপোর্ট অপেক্ষায়',
      zero: 'কোনো রিপোর্ট নেই',
    );
    return '$_temp0';
  }

  @override
  String caSectionsNoCr(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি সেকশনে সিআর নেই',
      zero: 'সব সেকশনে সিআর আছে',
    );
    return '$_temp0';
  }

  @override
  String caOpenBlood(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি রক্তের অনুরোধ খোলা',
      zero: 'কোনো খোলা রক্তের অনুরোধ নেই',
    );
    return '$_temp0';
  }

  @override
  String get caRecent => 'সাম্প্রতিক ভেরিফিকেশন';

  @override
  String get caRecentEmpty => 'এখনো কিছু নেই।';

  @override
  String get caSearchStudents => 'শিক্ষার্থী খোঁজো';

  @override
  String get caFilterVerified => 'ভেরিফায়েড';

  @override
  String get caFilterAll => 'সবাই';

  @override
  String get caNoStudents => 'কোনো শিক্ষার্থী পাওয়া যায়নি।';

  @override
  String get caStudentTitle => 'শিক্ষার্থী';

  @override
  String get caGroups => 'গ্রুপ';

  @override
  String get caNoGroups => 'কোনো গ্রুপে নেই।';

  @override
  String get caHistory => 'ভেরিফিকেশনের ইতিহাস';

  @override
  String get caHistoryEmpty => 'এখনো কোনো ইতিহাস নেই।';

  @override
  String caVouchedBy(String name, String time) {
    return '$name নিশ্চিত করেছে · $time';
  }

  @override
  String caConfirmedByCr(String name, String time) {
    return 'সিআর $name কনফার্ম করেছে · $time';
  }

  @override
  String caVerifiedByAdmin(String name, String time) {
    return 'ক্যাম্পাস অ্যাডমিন $name ভেরিফাই করেছে · $time';
  }

  @override
  String caVerifiedByEmail(String time) {
    return 'বিশ্ববিদ্যালয়ের ইমেইলে ভেরিফায়েড · $time';
  }

  @override
  String caVerifiedByTeam(String time) {
    return 'ভার্সিটিকথা টিম ভেরিফাই করেছে · $time';
  }

  @override
  String caHistoryRemoved(String reason) {
    return 'তুলে নেওয়া হয়েছে: $reason';
  }

  @override
  String get caVouchedByList => 'যারা নিশ্চিত করেছে';

  @override
  String get caVerify => 'ভেরিফাই করো';

  @override
  String get caUnverify => 'ভেরিফিকেশন তুলে নাও';

  @override
  String get caReasonLabel => 'কারণ';

  @override
  String get caReasonRequired => 'একটি কারণ লেখো।';

  @override
  String get caUnverifyBody => 'কারণ লেখো। কারণটি ইতিহাসে থেকে যাবে।';

  @override
  String get caEmailVerifiedNote =>
      'বিশ্ববিদ্যালয়ের ইমেইলে ভেরিফায়েড: শুধু ভার্সিটিকথা টিম এটা বদলাতে পারে।';

  @override
  String get caBlockVouching => 'নিশ্চিত করা বন্ধ করো';

  @override
  String get caUnblockVouching => 'আবার নিশ্চিত করতে দাও';

  @override
  String get caBlockBody =>
      'ও আর অন্যের হয়ে নিশ্চিত বা কনফার্ম করতে পারবে না। কারণ লেখো।';

  @override
  String get caBlockedPill => 'নিশ্চিত করতে পারে না';

  @override
  String caVerifiedSnack(String name) {
    return '$name এখন ভেরিফায়েড';
  }

  @override
  String get caUnverifiedSnack => 'ভেরিফিকেশন তুলে নেওয়া হয়েছে';

  @override
  String get caBlockedSnack => 'নিশ্চিত করা বন্ধ করা হয়েছে';

  @override
  String get caUnblockedSnack => 'আবার নিশ্চিত করতে পারবে';

  @override
  String caVouchesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি নিশ্চিতকরণ';
  }

  @override
  String caHelpedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString জনের জন্য নিশ্চিত বা কনফার্ম করেছে';
  }

  @override
  String get caAskTeam => 'ভার্সিটিকথা টিমকে জানাও';

  @override
  String get caAskTeamNote => 'টিমকে কী জানাতে চাও?';

  @override
  String get caAskTeamSend => 'পাঠাও';

  @override
  String get caAskTeamSent => 'ভার্সিটিকথা টিমকে পাঠানো হয়েছে';

  @override
  String get caSectionNoCr => 'সিআর নেই';

  @override
  String get caRemoveCr => 'সিআর সরাও';

  @override
  String get caSectionCrs => 'সিআর';

  @override
  String get caSectionStudents => 'শিক্ষার্থী';

  @override
  String get caSectionHint =>
      'সিআর বানাতে এই সেকশনের একজন ভেরিফায়েড শিক্ষার্থীকে খোঁজো।';

  @override
  String caCrMadeSnack(String name) {
    return '$name এখন সিআর';
  }

  @override
  String caCrRemovedSnack(String name) {
    return '$name আবার সাধারণ সদস্য';
  }

  @override
  String get caNoSections => 'এখনো কোনো সেকশন নেই।';

  @override
  String get caBusRepsEmpty => 'এখনো কোনো বাস প্রতিনিধি নেই।';

  @override
  String get caAddBusRep => 'বাস প্রতিনিধি যোগ করো';

  @override
  String get caRemove => 'সরাও';

  @override
  String get caReportHide => 'লুকাও';

  @override
  String get caReportRestore => 'ফিরিয়ে আনো';

  @override
  String get caReportDismiss => 'বাদ দাও';

  @override
  String get caReportsEmpty => 'কোনো রিপোর্ট করা পোস্ট নেই।';

  @override
  String get caReportPost => 'পোস্ট';

  @override
  String get caReportComment => 'মন্তব্য';

  @override
  String get caReportHidden => 'লুকানো';

  @override
  String caReportCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি রিপোর্ট';
  }

  @override
  String get caBloodEmpty => 'কোনো খোলা রক্তের অনুরোধ নেই।';

  @override
  String get caBloodClose => 'বন্ধ করো';

  @override
  String get caBloodCloseTitle => 'অনুরোধটি বন্ধ করবে?';

  @override
  String get caBloodCloseReason => 'কারণ (ঐচ্ছিক)';

  @override
  String get caBloodClosedSnack => 'অনুরোধ বন্ধ করা হয়েছে';

  @override
  String get helpFeedback => 'সাহায্য ও মতামত';

  @override
  String get helpFeedbackHint => 'সমস্যা জানাও বা নতুন আইডিয়া দাও।';

  @override
  String get feedbackSend => 'মতামত পাঠাও';

  @override
  String get feedbackMine => 'আমার মতামত';

  @override
  String get feedbackKindBug => 'সমস্যা';

  @override
  String get feedbackKindIdea => 'আইডিয়া';

  @override
  String get feedbackKindOther => 'অন্যান্য';

  @override
  String get feedbackMessageLabel => 'তোমার বার্তা';

  @override
  String get feedbackMessageHint => 'কী হয়েছে, বা কী দেখতে চাও?';

  @override
  String feedbackTooShort(int min) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);

    return 'অন্তত $minStringটি অক্ষর লেখো।';
  }

  @override
  String feedbackScreenshots(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'স্ক্রিনশট (সর্বোচ্চ $maxStringটি)';
  }

  @override
  String get feedbackAddScreenshot => 'স্ক্রিনশট যোগ করো';

  @override
  String feedbackAttached(String info) {
    return 'সাথে যাবে: $info';
  }

  @override
  String get feedbackSendButton => 'পাঠাও';

  @override
  String get feedbackSentSnack => 'ধন্যবাদ! তোমার মতামত পেয়েছি।';

  @override
  String get feedbackLimit => 'আজ ১০টি পাঠিয়ে ফেলেছ। কাল আবার চেষ্টা করো।';

  @override
  String get feedbackStatusNew => 'নতুন';

  @override
  String get feedbackStatusSeen => 'দেখা হয়েছে';

  @override
  String get feedbackStatusPlanned => 'পরিকল্পনায়';

  @override
  String get feedbackStatusInProgress => 'চলছে';

  @override
  String get feedbackStatusDone => 'শেষ';

  @override
  String get feedbackStatusWontDo => 'করা হবে না';

  @override
  String get feedbackEmpty => 'তুমি এখনো কোনো মতামত পাঠাওনি';

  @override
  String get feedbackEmptyBody =>
      'সমস্যা পেয়েছ বা আইডিয়া আছে? আমরা সবকিছু পড়ি।';

  @override
  String get feedbackTitle => 'মতামত';

  @override
  String get feedbackTeam => 'ভার্সিটিকথা টিম';

  @override
  String get feedbackYou => 'তুমি';

  @override
  String get feedbackReplyHint => 'উত্তর লেখো';

  @override
  String get feedbackReplySend => 'উত্তর পাঠাও';

  @override
  String get feedbackClosedNote => 'এটি বন্ধ, তবুও টিম তোমার উত্তর পড়বে।';

  @override
  String get feedbackNotFound => 'এই মতামতটি পাওয়া যাচ্ছে না।';

  @override
  String get inviteFriendsTitle => 'বন্ধুদের ডাকো';

  @override
  String inviteStats(int invited, int joined) {
    final intl.NumberFormat invitedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String invitedString = invitedNumberFormat.format(invited);
    final intl.NumberFormat joinedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String joinedString = joinedNumberFormat.format(joined);

    return '$invitedString জনকে ডেকেছ · $joinedString জন যোগ দিয়েছে';
  }

  @override
  String get inviteCountsRule =>
      'বন্ধু ভেরিফাই হয়ে ৩ দিন অ্যাপ ব্যবহার করলে গোনা হবে।';

  @override
  String get inviteShareButton => 'তোমার লিংক শেয়ার করো';

  @override
  String inviteShareText(String app, String link) {
    return 'আমার সাথে $app-এ এসো: ক্লাস রুটিন, রিমাইন্ডার আর ক্যাম্পাস, সব এক অ্যাপে। $link';
  }

  @override
  String get invitePendingTitle => 'এখনো গোনা হয়নি';

  @override
  String invitePendingLine(String name, String status, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$name · $status · ৩ দিনের $daysString দিন';
  }

  @override
  String get inviteStatusVerified => 'ভেরিফায়েড';

  @override
  String get inviteStatusNotVerified => 'এখনো ভেরিফাই হয়নি';

  @override
  String get badgesTitle => 'ব্যাজ';

  @override
  String get badgesEmpty => 'এখনো কোনো ব্যাজ নেই। এভাবে পেতে পারো।';

  @override
  String get badgesLockedTitle => 'এখনো পাওনি';

  @override
  String get badgeTierBronze => 'ব্রোঞ্জ';

  @override
  String get badgeTierSilver => 'সিলভার';

  @override
  String get badgeTierGold => 'গোল্ড';

  @override
  String badgeTiersLine(int bronze, int silver, int gold) {
    final intl.NumberFormat bronzeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bronzeString = bronzeNumberFormat.format(bronze);
    final intl.NumberFormat silverNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String silverString = silverNumberFormat.format(silver);
    final intl.NumberFormat goldNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String goldString = goldNumberFormat.format(gold);

    return 'ব্রোঞ্জ $bronzeString · সিলভার $silverString · গোল্ড $goldString';
  }

  @override
  String get badgePrivateNote => 'শুধু তুমি এটা দেখতে পাও';

  @override
  String get badgeShowByName => 'আমার নামের পাশে দেখাও';

  @override
  String get badgeShownByName => 'তোমার নামের পাশে দেখানো হচ্ছে';

  @override
  String get badgeStopShowing => 'দেখানো বন্ধ করো';

  @override
  String get badgeNowShown => 'এখন তোমার নামের পাশে দেখা যাবে';

  @override
  String get badgeNoLongerShown => 'নামের পাশে আর কোনো ব্যাজ দেখা যাবে না';

  @override
  String get badgeNotHeld => 'এই ব্যাজ তোমার নেই (আর)।';

  @override
  String get badgePrivateCant => 'প্রাইভেট ব্যাজ নামের পাশে দেখানো যায় না।';

  @override
  String badgeEarnedOn(String date) {
    return 'পেয়েছ $date';
  }

  @override
  String get badgeLocked => 'এখনো পাওনি';

  @override
  String get badgeNameVerified => 'ভেরিফায়েড শিক্ষার্থী';

  @override
  String get badgeHowVerified =>
      'বিশ্ববিদ্যালয়ের ইমেইল, সিআর বা সহপাঠীদের মাধ্যমে ভেরিফাই করো।';

  @override
  String get badgeNameFounding => 'প্রথম দিকের শিক্ষার্থী';

  @override
  String get badgeHowFounding => '২০২৭ সালের ১ এপ্রিলের আগে যোগ দাও।';

  @override
  String get badgeNameCr => 'সিআর';

  @override
  String get badgeHowCr => 'কোনো ক্লাস গ্রুপের সিআর হও।';

  @override
  String get badgeNameCampusAdmin => 'ক্যাম্পাস অ্যাডমিন';

  @override
  String get badgeHowCampusAdmin =>
      'অ্যাপে নিজের বিশ্ববিদ্যালয় চালানোর দায়িত্ব পাও।';

  @override
  String get badgeNameBusRep => 'ট্রান্সপোর্ট প্রতিনিধি';

  @override
  String get badgeHowBusRep => 'বিশ্ববিদ্যালয়ের ট্রান্সপোর্ট প্রতিনিধি হও।';

  @override
  String get badgeNameOfficial => 'কর্তৃপক্ষ';

  @override
  String get badgeHowOfficial => 'ভার্সিটি কথায় বিশ্ববিদ্যালয়ের স্টাফ হও।';

  @override
  String get badgeNameBloodDonor => 'রক্তদাতা';

  @override
  String get badgeHowBloodDonor => 'রক্তদাতা হিসেবে নিবন্ধন করো।';

  @override
  String get badgeNameLifeSaver => 'জীবনরক্ষাকারী';

  @override
  String get badgeHowLifeSaver => 'অ্যাপে তোমার রক্তদান চিহ্নিত করো।';

  @override
  String get badgeNameBusBuddy => 'বাস বন্ধু';

  @override
  String get badgeHowBusBuddy =>
      'লাইভ বাস ট্রিপ শেয়ার করো, যাতে সহপাঠীরা বাস দেখতে পায়।';

  @override
  String get badgeNameSectionBuilder => 'সেকশন নির্মাতা';

  @override
  String get badgeHowSectionBuilder => 'অনেক সদস্যের গ্রুপের সিআর হও।';

  @override
  String get badgeNameConnector => 'কানেক্টর';

  @override
  String get badgeHowConnector =>
      'যে বন্ধুরা যোগ দিয়ে সক্রিয় হয়, তাদের ডাকো।';

  @override
  String get badgeNameBugHunter => 'বাগ শিকারি';

  @override
  String get badgeHowBugHunter => 'যে বাগ রিপোর্ট আমরা ঠিক করি, সেগুলো পাঠাও।';

  @override
  String get badgeNameHelper => 'সহায়ক';

  @override
  String get badgeHowHelper => 'তোমার কমেন্ট ও উত্তরে লাইক পাও।';

  @override
  String get badgeNameCampusVoice => 'ক্যাম্পাসের কণ্ঠ';

  @override
  String get badgeHowCampusVoice => 'যে সমস্যা তুলে ধরো, তা সমাধান হোক।';

  @override
  String get leaderboardShowTitle => 'লিডারবোর্ডে আমাকে দেখাও';

  @override
  String get leaderboardShowHint =>
      'বন্ধ থাকলে \"তোমার বিশ্ববিদ্যালয়ের একজন শিক্ষার্থী\" দেখাবে।';

  @override
  String profileJoined(String date) {
    return 'যোগ দিয়েছে $date';
  }

  @override
  String get profilePostsTitle => 'পোস্ট';

  @override
  String get profileNoPosts => 'নাম দিয়ে করা কোনো পোস্ট এখনো নেই।';

  @override
  String profileInvitesJoined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString জন বন্ধুকে এনেছে';
  }

  @override
  String get profileNotFound => 'এই প্রোফাইল দেখা যাচ্ছে না।';

  @override
  String get roleCampusAdmin => 'ক্যাম্পাস অ্যাডমিন';

  @override
  String get roleBusRep => 'ট্রান্সপোর্ট প্রতিনিধি';

  @override
  String get roleOfficial => 'কর্তৃপক্ষ';

  @override
  String get profileOpen => 'প্রোফাইল দেখো';

  @override
  String get campaignsTitle => 'পুরস্কারের ক্যাম্পেইন';

  @override
  String get campaignLive => 'চলছে';

  @override
  String get campaignEnded => 'শেষ';

  @override
  String get campaignAnnounced => 'বিজয়ী ঘোষণা হয়েছে';

  @override
  String campaignLeftDays(int days, int hours) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return 'আর $daysString দিন $hoursString ঘণ্টা';
  }

  @override
  String campaignLeftHours(int hours, int minutes) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'আর $hoursString ঘণ্টা $minutesString মিনিট';
  }

  @override
  String campaignLeftMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'আর $minutesString মিনিট';
  }

  @override
  String campaignTopPrize(String prize) {
    return 'সেরা পুরস্কার: $prize';
  }

  @override
  String campaignMyRank(int rank, String score) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);

    return 'র‍্যাংক $rankString · $score';
  }

  @override
  String get campaignNoRank => 'এখনো র‍্যাংক নেই · বন্ধুদের ডেকে এগিয়ে যাও';

  @override
  String campaignScore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি আমন্ত্রণ';
  }

  @override
  String get campaignPrizes => 'পুরস্কার';

  @override
  String campaignPrizeRank(int rank) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);

    return '$rankString নম্বর';
  }

  @override
  String campaignPrizeRange(int from, int to) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String toString = toNumberFormat.format(to);

    return '$fromString–$toString নম্বর';
  }

  @override
  String get campaignScopeAll => 'বাংলাদেশ';

  @override
  String get campaignScopeUniversity => 'আমার বিশ্ববিদ্যালয়';

  @override
  String get campaignLeaderboard => 'লিডারবোর্ড';

  @override
  String get campaignLeaderboardEmpty => 'লিডারবোর্ডে এখনো কেউ নেই।';

  @override
  String get campaignHowTitle => 'আমন্ত্রণ কীভাবে গোনা হয়';

  @override
  String get campaignRules => 'নিয়মাবলি';

  @override
  String get campaignNotFound => 'এই ক্যাম্পেইন পাওয়া যাচ্ছে না।';

  @override
  String campaignWhenEnds(String date) {
    return 'শেষ হবে $date';
  }

  @override
  String get winTitle => 'তুমি জিতেছ!';

  @override
  String winPrize(int rank, String prize) {
    final intl.NumberFormat rankNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rankString = rankNumberFormat.format(rank);

    return '$rankString নম্বর · $prize';
  }

  @override
  String get claimIntro =>
      'পুরস্কার কোথায় পাঠাব জানাও। এটা শুধু পৌঁছে দেওয়ার জন্য ব্যবহার করা হবে।';

  @override
  String get claimFullName => 'পুরো নাম';

  @override
  String get claimPhone => 'ফোন নম্বর';

  @override
  String get claimAddress => 'ডেলিভারির ঠিকানা';

  @override
  String get claimNote => 'নোট (ঐচ্ছিক)';

  @override
  String get claimSend => 'পাঠাও';

  @override
  String get claimNameRequired => 'পুরো নাম লেখো।';

  @override
  String get claimPhoneInvalid => 'যে নম্বরে ফোন করা যায়, সেটা লেখো।';

  @override
  String get claimAddressRequired => 'কোথায় পৌঁছে দেব, সেটা লেখো।';

  @override
  String get claimDone => 'আমরা তোমার সাথে যোগাযোগ করব';

  @override
  String get claimDoneBody =>
      'ধন্যবাদ! তোমার তথ্য পেয়েছি। পুরস্কারের জন্য তোমার সাথে যোগাযোগ করব।';

  @override
  String get claimNotWinner => 'শুধু বিজয়ীরা পুরস্কার নিতে পারে।';
}
