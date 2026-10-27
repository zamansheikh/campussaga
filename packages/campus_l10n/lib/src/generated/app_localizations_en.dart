// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Campus Saga';

  @override
  String get navToday => 'Today';

  @override
  String get navRoutine => 'Routine';

  @override
  String get navProfile => 'Profile';

  @override
  String get todayEmptyTitle => 'No classes yet';

  @override
  String get todayEmptyMessage =>
      'Join your class group to see today\'s classes and get reminders.';

  @override
  String get joinClassGroup => 'Join class group';

  @override
  String get routineEmptyTitle => 'Your weekly routine';

  @override
  String get routineEmptyMessage =>
      'Once you join a class group, the full week appears here.';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get welcomeTitle => 'Sign in with your university account';

  @override
  String get welcomeSubtitle =>
      'Only verified students can join. Your university email shows you\'re a student.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get useUniversityEmail => 'Use university email instead';

  @override
  String get errorUniversityEmailRequired =>
      'This isn\'t a university account. Choose your university Google account, or sign in with your university email.';

  @override
  String get errorNetwork => 'No internet connection. Please try again.';

  @override
  String get errorGoogleFailed =>
      'Google sign-in didn\'t work. Please try again.';

  @override
  String get errorSessionEnded => 'You were signed out. Please sign in again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign out';
}
