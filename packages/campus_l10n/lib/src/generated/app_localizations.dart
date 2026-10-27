import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// Product name. Change here when rebranding.
  ///
  /// In en, this message translates to:
  /// **'Campus Saga'**
  String get appName;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get navRoutine;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @todayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Join your class group to see today\'s classes and get reminders.'**
  String get todayEmptyMessage;

  /// No description provided for @joinClassGroup.
  ///
  /// In en, this message translates to:
  /// **'Join class group'**
  String get joinClassGroup;

  /// No description provided for @routineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekly routine'**
  String get routineEmptyTitle;

  /// No description provided for @routineEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Once you join a class group, the full week appears here.'**
  String get routineEmptyMessage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your university account'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only verified students can join. Your university email shows you\'re a student.'**
  String get welcomeSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @useUniversityEmail.
  ///
  /// In en, this message translates to:
  /// **'Use university email instead'**
  String get useUniversityEmail;

  /// No description provided for @errorUniversityEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a university account. Choose your university Google account, or sign in with your university email.'**
  String get errorUniversityEmailRequired;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get errorNetwork;

  /// No description provided for @errorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in didn\'t work. Please try again.'**
  String get errorGoogleFailed;

  /// No description provided for @errorSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'You were signed out. Please sign in again.'**
  String get errorSessionEnded;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @emailSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get emailSignInTitle;

  /// No description provided for @emailStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your university email'**
  String get emailStepTitle;

  /// No description provided for @emailStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a 6-digit code. Only the email your university gave you works.'**
  String get emailStepSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'University email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'yourname@university.edu.bd'**
  String get emailHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @codeStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get codeStepTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String codeSentTo(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendCodeIn(String time);

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @codeSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Check your spam folder.'**
  String get codeSpamHint;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorEmailInvalid;

  /// No description provided for @errorNotUniversityEmail.
  ///
  /// In en, this message translates to:
  /// **'This email isn\'t from a supported university. Use the email your university gave you.'**
  String get errorNotUniversityEmail;

  /// No description provided for @errorCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. {count, plural, =1{1 try left.} other{{count} tries left.}}'**
  String errorCodeInvalid(int count);

  /// No description provided for @errorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Tap \"Resend code\" to get a new one.'**
  String get errorCodeExpired;

  /// No description provided for @errorCodeTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Tap \"Resend code\" to get a new one.'**
  String get errorCodeTooManyAttempts;

  /// No description provided for @errorCodeLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many codes requested. Please try again later.'**
  String get errorCodeLimit;

  /// No description provided for @errorEmailSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the email. Please try again.'**
  String get errorEmailSendFailed;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @setupProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get setupProfileTitle;

  /// No description provided for @setupProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your department and batch help us find your class. Your name is shown to classmates in class groups; campus issues can still be posted anonymously.'**
  String get setupProfileSubtitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayNameLabel;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @departmentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CSE'**
  String get departmentHint;

  /// No description provided for @batchLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get batchLabel;

  /// No description provided for @batchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 61 or Spring 2024'**
  String get batchHint;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProfile;

  /// No description provided for @setupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get setupLater;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @errorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This is required.'**
  String get errorFieldRequired;

  /// No description provided for @errorFieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'This is too long.'**
  String get errorFieldTooLong;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile and signs you out on every device. It can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of the app is no longer supported. Please update to keep using it.'**
  String get updateRequiredBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateFromStore.
  ///
  /// In en, this message translates to:
  /// **'Please update the app from your app store.'**
  String get updateFromStore;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Your class, always on time'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Today\'s classes, room changes from your CR, and a reminder before every class.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Raise campus issues together'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Report a problem, add your \"me too\", and follow it until it\'s solved.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Verified students only'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Only verified university emails can join. Post campus issues without your name. We never sell your data.'**
  String get onboarding3Body;

  /// No description provided for @illusNextClass.
  ///
  /// In en, this message translates to:
  /// **'Next class'**
  String get illusNextClass;

  /// No description provided for @illusStartsIn.
  ///
  /// In en, this message translates to:
  /// **'in 25 min'**
  String get illusStartsIn;

  /// No description provided for @illusRoomChanged.
  ///
  /// In en, this message translates to:
  /// **'Room changed to 504'**
  String get illusRoomChanged;

  /// No description provided for @illusReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get illusReminder;

  /// No description provided for @illusIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Library Wi-Fi keeps dropping'**
  String get illusIssueTitle;

  /// No description provided for @illusMeToo.
  ///
  /// In en, this message translates to:
  /// **'Me too'**
  String get illusMeToo;

  /// No description provided for @illusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get illusInProgress;

  /// No description provided for @illusAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Posted anonymously'**
  String get illusAnonymous;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Your class and your campus, in one app.'**
  String get signInTagline;

  /// No description provided for @signInLegal.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our {policy}.'**
  String signInLegal(String policy);

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @todayStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get todayStepsTitle;

  /// No description provided for @todayStep1.
  ///
  /// In en, this message translates to:
  /// **'Join your class group with a code from your CR'**
  String get todayStep1;

  /// No description provided for @todayStep2.
  ///
  /// In en, this message translates to:
  /// **'See today\'s classes and rooms at a glance'**
  String get todayStep2;

  /// No description provided for @todayStep3.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder before each class'**
  String get todayStep3;

  /// No description provided for @verifiedStudent.
  ///
  /// In en, this message translates to:
  /// **'Verified student'**
  String get verifiedStudent;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Add department and batch'**
  String get completeProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Match your phone\'s setting'**
  String get themeSystemHint;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @madeFor.
  ///
  /// In en, this message translates to:
  /// **'Made for students in Bangladesh'**
  String get madeFor;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountHint;

  /// No description provided for @setupProfileStep.
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get setupProfileStep;

  /// No description provided for @editProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Classmates see your name in class groups.'**
  String get editProfileHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
