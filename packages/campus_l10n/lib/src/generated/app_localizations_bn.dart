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
}
