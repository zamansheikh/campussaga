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

  @override
  String get emailSignInTitle => 'Sign in with email';

  @override
  String get emailStepTitle => 'Enter your university email';

  @override
  String get emailStepSubtitle =>
      'We\'ll send you a 6-digit code. Only the email your university gave you works.';

  @override
  String get emailLabel => 'University email';

  @override
  String get emailHint => 'yourname@university.edu.bd';

  @override
  String get sendCode => 'Send code';

  @override
  String get codeStepTitle => 'Enter the code';

  @override
  String codeSentTo(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get verifyCode => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get codeSpamHint => 'Can\'t find it? Check your spam folder.';

  @override
  String get errorEmailInvalid => 'Enter a valid email address.';

  @override
  String get errorNotUniversityEmail =>
      'This email isn\'t from a supported university. Use the email your university gave you.';

  @override
  String errorCodeInvalid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left.',
      one: '1 try left.',
    );
    return 'That code isn\'t right. $_temp0';
  }

  @override
  String get errorCodeExpired =>
      'This code has expired. Tap \"Resend code\" to get a new one.';

  @override
  String get errorCodeTooManyAttempts =>
      'Too many wrong codes. Tap \"Resend code\" to get a new one.';

  @override
  String get errorCodeLimit =>
      'Too many codes requested. Please try again later.';

  @override
  String get errorEmailSendFailed =>
      'We couldn\'t send the email. Please try again.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get setupProfileTitle => 'Set up your profile';

  @override
  String get setupProfileSubtitle =>
      'Your department and batch help us find your class. Your name is shown to classmates in class groups; campus issues can still be posted anonymously.';

  @override
  String get displayNameLabel => 'Your name';

  @override
  String get departmentLabel => 'Department';

  @override
  String get departmentHint => 'e.g. CSE';

  @override
  String get batchLabel => 'Batch';

  @override
  String get batchHint => 'e.g. 61 or Spring 2024';

  @override
  String get saveProfile => 'Save';

  @override
  String get setupLater => 'Later';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get errorFieldRequired => 'This is required.';

  @override
  String get errorFieldTooLong => 'This is too long.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile and signs you out on every device. It can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete my account';

  @override
  String get cancel => 'Cancel';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of the app is no longer supported. Please update to keep using it.';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateFromStore => 'Please update the app from your app store.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboarding1Title => 'Your class, always on time';

  @override
  String get onboarding1Body =>
      'Today\'s classes, room changes from your CR, and a reminder before every class.';

  @override
  String get onboarding2Title => 'Raise campus issues together';

  @override
  String get onboarding2Body =>
      'Report a problem, add your \"me too\", and follow it until it\'s solved.';

  @override
  String get onboarding3Title => 'Verified students only';

  @override
  String get onboarding3Body =>
      'Only verified university emails can join. Post campus issues without your name. We never sell your data.';

  @override
  String get illusNextClass => 'Next class';

  @override
  String get illusStartsIn => 'in 25 min';

  @override
  String get illusRoomChanged => 'Room changed to 504';

  @override
  String get illusReminder => 'Reminder set';

  @override
  String get illusIssueTitle => 'Library Wi-Fi keeps dropping';

  @override
  String get illusMeToo => 'Me too';

  @override
  String get illusInProgress => 'In progress';

  @override
  String get illusAnonymous => 'Posted anonymously';

  @override
  String get signInTagline => 'Your class and your campus, in one app.';

  @override
  String signInLegal(String policy) {
    return 'By continuing, you agree to our $policy.';
  }

  @override
  String get orDivider => 'or';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get todayStepsTitle => 'How it works';

  @override
  String get todayStep1 => 'Join your class group with a code from your CR';

  @override
  String get todayStep2 => 'See today\'s classes and rooms at a glance';

  @override
  String get todayStep3 => 'Get a reminder before each class';

  @override
  String get verifiedStudent => 'Verified student';

  @override
  String get completeProfile => 'Add department and batch';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get themeSystemHint => 'Match your phone\'s setting';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get madeFor => 'Made for students in Bangladesh';

  @override
  String get deleteAccountHint => 'Permanently remove your account';

  @override
  String get setupProfileStep => 'Last step';

  @override
  String get editProfileHint => 'Classmates see your name in class groups.';
}
