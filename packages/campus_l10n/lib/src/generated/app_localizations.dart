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
  /// **'Sign in to get started'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your university email to join as a verified student. No university email? Continue with Google using any account.'**
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
  /// **'This email isn\'t from a supported university. No university email? Go back and continue with Google.'**
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

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @useAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get useAnotherAccount;

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

  /// No description provided for @classGroups.
  ///
  /// In en, this message translates to:
  /// **'Class groups'**
  String get classGroups;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCode;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create a class group'**
  String get createGroup;

  /// No description provided for @createGroupHint.
  ///
  /// In en, this message translates to:
  /// **'For CRs: enter your section\'s routine once and share the code.'**
  String get createGroupHint;

  /// No description provided for @imTheCr.
  ///
  /// In en, this message translates to:
  /// **'I\'m the CR, create a group'**
  String get imTheCr;

  /// No description provided for @roleCr.
  ///
  /// In en, this message translates to:
  /// **'CR'**
  String get roleCr;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String membersCount(int count);

  /// No description provided for @classesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No classes yet} =1{1 class a week} other{{count} classes a week}}'**
  String classesCount(int count);

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join your class group'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-letter code from your CR.'**
  String get joinSubtitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get joinCodeLabel;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get joinAction;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in this group'**
  String get alreadyMember;

  /// No description provided for @openGroup.
  ///
  /// In en, this message translates to:
  /// **'Open group'**
  String get openGroup;

  /// No description provided for @createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be the CR. Classmates join with a code and see the routine you enter.'**
  String get createSubtitle;

  /// No description provided for @sectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get sectionLabel;

  /// No description provided for @sectionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A'**
  String get sectionHint;

  /// No description provided for @semesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semesterLabel;

  /// No description provided for @semesterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fall 2026'**
  String get semesterHint;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createAction;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group details'**
  String get editGroup;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite classmates'**
  String get inviteTitle;

  /// No description provided for @inviteHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code in your class Messenger group.'**
  String get inviteHint;

  /// No description provided for @copyInvite.
  ///
  /// In en, this message translates to:
  /// **'Copy invite'**
  String get copyInvite;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied. Paste it in your class group.'**
  String get inviteCopied;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join {group} on {app}: open the app, tap \"Join with a code\" and enter {code}'**
  String inviteMessage(String group, String app, String code);

  /// No description provided for @weeklyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Weekly routine'**
  String get weeklyRoutine;

  /// No description provided for @addClass.
  ///
  /// In en, this message translates to:
  /// **'Add class'**
  String get addClass;

  /// No description provided for @editClass.
  ///
  /// In en, this message translates to:
  /// **'Edit class'**
  String get editClass;

  /// No description provided for @noClassesYetCr.
  ///
  /// In en, this message translates to:
  /// **'Add your section\'s classes. It takes a few minutes, once a semester.'**
  String get noClassesYetCr;

  /// No description provided for @noClassesYetMember.
  ///
  /// In en, this message translates to:
  /// **'Your CR hasn\'t added classes yet.'**
  String get noClassesYetMember;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @leaveGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this group?'**
  String get leaveGroupTitle;

  /// No description provided for @leaveGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Its classes disappear from your routine. You can join again with the code.'**
  String get leaveGroupBody;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this group for everyone?'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupBody.
  ///
  /// In en, this message translates to:
  /// **'The routine is removed for every student in the group. This can\'t be undone.'**
  String get deleteGroupBody;

  /// No description provided for @courseCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Course code'**
  String get courseCodeLabel;

  /// No description provided for @courseCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CSE311'**
  String get courseCodeHint;

  /// No description provided for @courseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Course title'**
  String get courseTitleLabel;

  /// No description provided for @teacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherLabel;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomLabel;

  /// No description provided for @startsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get startsLabel;

  /// No description provided for @endsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get endsLabel;

  /// No description provided for @classTheory.
  ///
  /// In en, this message translates to:
  /// **'Theory'**
  String get classTheory;

  /// No description provided for @classLab.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get classLab;

  /// No description provided for @saveAndAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Save and add another'**
  String get saveAndAddAnother;

  /// No description provided for @deleteClass.
  ///
  /// In en, this message translates to:
  /// **'Delete class'**
  String get deleteClass;

  /// No description provided for @errorEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'It must end after it starts.'**
  String get errorEndBeforeStart;

  /// No description provided for @nextClass.
  ///
  /// In en, this message translates to:
  /// **'Next class'**
  String get nextClass;

  /// No description provided for @nowInClass.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowInClass;

  /// No description provided for @startsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String startsInMinutes(int minutes);

  /// No description provided for @startsInHours.
  ///
  /// In en, this message translates to:
  /// **'in {hours} h {minutes} min'**
  String startsInHours(int hours, int minutes);

  /// No description provided for @endsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'ends in {minutes} min'**
  String endsInMinutes(int minutes);

  /// No description provided for @todaysClasses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s classes'**
  String get todaysClasses;

  /// No description provided for @noClassesToday.
  ///
  /// In en, this message translates to:
  /// **'No classes today'**
  String get noClassesToday;

  /// No description provided for @doneForToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get doneForToday;

  /// No description provided for @nextOn.
  ///
  /// In en, this message translates to:
  /// **'Next class: {day}'**
  String nextOn(String day);

  /// No description provided for @offlineNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing your saved routine.'**
  String get offlineNotice;

  /// No description provided for @roomShort.
  ///
  /// In en, this message translates to:
  /// **'Room {room}'**
  String roomShort(String room);

  /// No description provided for @routineNoClassesDay.
  ///
  /// In en, this message translates to:
  /// **'No classes on this day'**
  String get routineNoClassesDay;

  /// No description provided for @errorGroupNotFound.
  ///
  /// In en, this message translates to:
  /// **'No class group with this code at your university. Check the code with your CR.'**
  String get errorGroupNotFound;

  /// No description provided for @errorNotCr.
  ///
  /// In en, this message translates to:
  /// **'Only the CR can change this group.'**
  String get errorNotCr;

  /// No description provided for @errorGroupLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in 10 class groups. Leave one to join another.'**
  String get errorGroupLimit;

  /// No description provided for @errorGroupFull.
  ///
  /// In en, this message translates to:
  /// **'This class group is full.'**
  String get errorGroupFull;

  /// No description provided for @errorCrCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'You\'re the only CR. Make someone else CR in Members first, or delete the group.'**
  String get errorCrCannotLeave;

  /// No description provided for @errorSlotLimit.
  ///
  /// In en, this message translates to:
  /// **'This routine already has the most classes allowed.'**
  String get errorSlotLimit;

  /// No description provided for @deleteClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this class for everyone?'**
  String get deleteClassTitle;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Class reminders'**
  String get reminders;

  /// No description provided for @remindersOnValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String remindersOnValue(int minutes);

  /// No description provided for @remindersOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get remindersOff;

  /// No description provided for @remindersSwitch.
  ///
  /// In en, this message translates to:
  /// **'Remind me before each class'**
  String get remindersSwitch;

  /// No description provided for @remindersSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Works without internet.'**
  String get remindersSwitchHint;

  /// No description provided for @remindBefore.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get remindBefore;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @coursesHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off courses you don\'t attend.'**
  String get coursesHint;

  /// No description provided for @noCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'Courses appear here once you join a class group.'**
  String get noCoursesYet;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this app. Turn them on in your phone\'s settings, then try again.'**
  String get notificationsBlocked;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @exactAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind on time'**
  String get exactAlarmTitle;

  /// No description provided for @exactAlarmHint.
  ///
  /// In en, this message translates to:
  /// **'Without this, Android may show reminders a few minutes late.'**
  String get exactAlarmHint;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @reminderPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a class'**
  String get reminderPromptTitle;

  /// No description provided for @reminderPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Get a notification 10 minutes before each class.'**
  String get reminderPromptBody;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{course} in {minutes} min'**
  String notificationTitle(String course, int minutes);

  /// No description provided for @notificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Class reminders'**
  String get notificationChannel;

  /// No description provided for @notificationChannelHint.
  ///
  /// In en, this message translates to:
  /// **'A reminder before each class'**
  String get notificationChannelHint;

  /// No description provided for @classesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Class added} other{{count} classes added}}'**
  String classesAdded(int count);

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// No description provided for @daysHint.
  ///
  /// In en, this message translates to:
  /// **'Pick every day this class meets at this time.'**
  String get daysHint;

  /// No description provided for @errorPickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get errorPickDay;

  /// No description provided for @changeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get changeCancelled;

  /// No description provided for @changeMoved.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get changeMoved;

  /// No description provided for @changeExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra class'**
  String get changeExtra;

  /// No description provided for @cancelThisClass.
  ///
  /// In en, this message translates to:
  /// **'Cancel this class'**
  String get cancelThisClass;

  /// No description provided for @changeTimeOrRoom.
  ///
  /// In en, this message translates to:
  /// **'Change time or room'**
  String get changeTimeOrRoom;

  /// No description provided for @undoChange.
  ///
  /// In en, this message translates to:
  /// **'Undo change'**
  String get undoChange;

  /// No description provided for @removeExtraClass.
  ///
  /// In en, this message translates to:
  /// **'Remove extra class'**
  String get removeExtraClass;

  /// No description provided for @editWeeklyClass.
  ///
  /// In en, this message translates to:
  /// **'Edit weekly class'**
  String get editWeeklyClass;

  /// No description provided for @addExtraClass.
  ///
  /// In en, this message translates to:
  /// **'Add extra class'**
  String get addExtraClass;

  /// No description provided for @cancelClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel {course} on {date}?'**
  String cancelClassTitle(String course, String date);

  /// No description provided for @cancelClassBody.
  ///
  /// In en, this message translates to:
  /// **'Classmates see it as cancelled, and its reminder is removed. The weekly routine stays the same.'**
  String get cancelClassBody;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for classmates (optional)'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The teacher is on leave'**
  String get noteHint;

  /// No description provided for @keepClass.
  ///
  /// In en, this message translates to:
  /// **'Keep class'**
  String get keepClass;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel class'**
  String get confirmCancel;

  /// No description provided for @onlyThisDay.
  ///
  /// In en, this message translates to:
  /// **'Only for {date}. The weekly routine stays the same.'**
  String onlyThisDay(String date);

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @upcomingChanges.
  ///
  /// In en, this message translates to:
  /// **'Upcoming changes'**
  String get upcomingChanges;

  /// No description provided for @wasTime.
  ///
  /// In en, this message translates to:
  /// **'was {time}'**
  String wasTime(String time);

  /// No description provided for @changeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Classmates see it when they open the app.'**
  String get changeSaved;

  /// No description provided for @openGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Open class group'**
  String get openGroupAction;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @postAction.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postAction;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get newAnnouncement;

  /// No description provided for @announcementHint.
  ///
  /// In en, this message translates to:
  /// **'Write to your class, e.g. Bring a calculator tomorrow'**
  String get announcementHint;

  /// No description provided for @pinToTop.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get pinToTop;

  /// No description provided for @pinToTopHint.
  ///
  /// In en, this message translates to:
  /// **'Stays first until you unpin it. Only one can be pinned.'**
  String get pinToTopHint;

  /// No description provided for @pinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinAction;

  /// No description provided for @unpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinAction;

  /// No description provided for @pinnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedLabel;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this announcement for everyone?'**
  String get deleteAnnouncementTitle;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// No description provided for @noAnnouncementsCr.
  ///
  /// In en, this message translates to:
  /// **'Post updates for your class here: quizzes, things to bring, room news.'**
  String get noAnnouncementsCr;

  /// No description provided for @announcementPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted. Classmates see it when they open the app.'**
  String get announcementPosted;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get timeYesterday;

  /// No description provided for @errorAnnouncementGone.
  ///
  /// In en, this message translates to:
  /// **'This announcement was already deleted.'**
  String get errorAnnouncementGone;

  /// No description provided for @pushChannel.
  ///
  /// In en, this message translates to:
  /// **'Class updates'**
  String get pushChannel;

  /// No description provided for @pushChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Changes and announcements from your CR'**
  String get pushChannelHint;

  /// No description provided for @myCourses.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get myCourses;

  /// No description provided for @myCoursesHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off courses you don\'t take in this section, e.g. if you joined only for a retake. Only your own routine and reminders change.'**
  String get myCoursesHint;

  /// No description provided for @coursesShown.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} courses in your routine'**
  String coursesShown(int shown, int total);

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @makeCr.
  ///
  /// In en, this message translates to:
  /// **'Make CR'**
  String get makeCr;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get makeMember;

  /// No description provided for @stepDown.
  ///
  /// In en, this message translates to:
  /// **'Step down as CR'**
  String get stepDown;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the group?'**
  String removeMemberTitle(String name);

  /// No description provided for @removeMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They stop seeing this routine. They could join again with the code.'**
  String get removeMemberBody;

  /// No description provided for @crHint.
  ///
  /// In en, this message translates to:
  /// **'CRs edit the routine, post announcements and manage members. Up to 3 per group.'**
  String get crHint;

  /// No description provided for @unnamedStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get unnamedStudent;

  /// No description provided for @errorCrLimit.
  ///
  /// In en, this message translates to:
  /// **'A group can have at most 3 CRs.'**
  String get errorCrLimit;

  /// No description provided for @errorLastCr.
  ///
  /// In en, this message translates to:
  /// **'Make someone else CR first.'**
  String get errorLastCr;

  /// No description provided for @errorRemoveCr.
  ///
  /// In en, this message translates to:
  /// **'Make them a member first, then remove them.'**
  String get errorRemoveCr;

  /// No description provided for @errorPersonalLimit.
  ///
  /// In en, this message translates to:
  /// **'You already have the most personal classes allowed.'**
  String get errorPersonalLimit;

  /// No description provided for @newSemester.
  ///
  /// In en, this message translates to:
  /// **'Start new semester'**
  String get newSemester;

  /// No description provided for @newSemesterBody.
  ///
  /// In en, this message translates to:
  /// **'This clears the weekly routine and its changes. Members, the join code and announcements stay, and classmates are told.'**
  String get newSemesterBody;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startAction;

  /// No description provided for @personalClasses.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalClasses;

  /// No description provided for @addPersonalClass.
  ///
  /// In en, this message translates to:
  /// **'Add personal class'**
  String get addPersonalClass;

  /// No description provided for @editPersonalClass.
  ///
  /// In en, this message translates to:
  /// **'Edit personal class'**
  String get editPersonalClass;

  /// No description provided for @personalHint.
  ///
  /// In en, this message translates to:
  /// **'Only you see these: tuition, a job, a lab with another section.'**
  String get personalHint;

  /// No description provided for @personalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personalNameLabel;

  /// No description provided for @personalNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tuition'**
  String get personalNameHint;

  /// No description provided for @personalDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get personalDetailsLabel;

  /// No description provided for @placeLabel.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeLabel;

  /// No description provided for @addToRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add to your routine'**
  String get addToRoutine;

  /// No description provided for @extraClassHint.
  ///
  /// In en, this message translates to:
  /// **'For your class group, one day only'**
  String get extraClassHint;

  /// No description provided for @deletePersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this personal class?'**
  String get deletePersonalTitle;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders arriving late?'**
  String get batteryTitle;

  /// No description provided for @batteryBody.
  ///
  /// In en, this message translates to:
  /// **'{brand} phones can stop apps in the background. Let this app run without battery limits: Settings → Apps → {app} → Battery → Unrestricted (or No restrictions).'**
  String batteryBody(String brand, String app);

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Found a bug or have an idea? Tell us.'**
  String get sendFeedbackHint;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @verifyWithUniEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify with university email'**
  String get verifyWithUniEmail;

  /// No description provided for @verifyHint.
  ///
  /// In en, this message translates to:
  /// **'Get the Verified badge with a code sent to your university email.'**
  String get verifyHint;

  /// No description provided for @chooseUniversity.
  ///
  /// In en, this message translates to:
  /// **'Choose your university'**
  String get chooseUniversity;

  /// No description provided for @chooseUniversityHint.
  ///
  /// In en, this message translates to:
  /// **'You signed in without a university email, so choose your university. You show as not verified until you verify with a university email.'**
  String get chooseUniversityHint;

  /// No description provided for @searchUniversity.
  ///
  /// In en, this message translates to:
  /// **'Search universities'**
  String get searchUniversity;

  /// No description provided for @universityLabel.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get universityLabel;

  /// No description provided for @changeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAction;

  /// No description provided for @verifiedNow.
  ///
  /// In en, this message translates to:
  /// **'You\'re now a verified student'**
  String get verifiedNow;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify you\'re a student'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email your university gave you. We\'ll send a 6-digit code to it.'**
  String get verifySubtitle;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has its own account. Sign out and sign in with it instead.'**
  String get errorEmailInUse;

  /// No description provided for @errorAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'You\'re already verified.'**
  String get errorAlreadyVerified;

  /// No description provided for @errorUniversityRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose your university first in your profile.'**
  String get errorUniversityRequired;

  /// No description provided for @errorChooseUniversity.
  ///
  /// In en, this message translates to:
  /// **'Choose your university to continue.'**
  String get errorChooseUniversity;

  /// No description provided for @errorNotUniversityEmailVerify.
  ///
  /// In en, this message translates to:
  /// **'This email isn\'t from a supported university. Use the email your university gave you.'**
  String get errorNotUniversityEmailVerify;

  /// No description provided for @changeUniversity.
  ///
  /// In en, this message translates to:
  /// **'Change university'**
  String get changeUniversity;

  /// No description provided for @changeWithEmail.
  ///
  /// In en, this message translates to:
  /// **'With my new university email'**
  String get changeWithEmail;

  /// No description provided for @changeWithEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Stay verified at your new university'**
  String get changeWithEmailHint;

  /// No description provided for @changeWithoutEmail.
  ///
  /// In en, this message translates to:
  /// **'Without a university email'**
  String get changeWithoutEmail;

  /// No description provided for @changeWithoutEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Pick it from the list; you\'ll show as not verified'**
  String get changeWithoutEmailHint;

  /// No description provided for @leaveVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to {university}?'**
  String leaveVerifiedTitle(String university);

  /// No description provided for @leaveVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll show as not verified until you verify with an email from your new university. Your class groups stay.'**
  String get leaveVerifiedBody;

  /// No description provided for @changeUniversitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email at your new university. We\'ll send a 6-digit code to it.'**
  String get changeUniversitySubtitle;

  /// No description provided for @universityChanged.
  ///
  /// In en, this message translates to:
  /// **'University changed'**
  String get universityChanged;

  /// No description provided for @moveAction.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get moveAction;
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
