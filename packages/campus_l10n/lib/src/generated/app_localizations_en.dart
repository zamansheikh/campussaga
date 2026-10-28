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
  String get welcomeTitle => 'Sign in to get started';

  @override
  String get welcomeSubtitle =>
      'Use your university email to join as a verified student. No university email? Continue with Google using any account.';

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
      'This email isn\'t from a supported university. No university email? Go back and continue with Google.';

  @override
  String errorCodeInvalid(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tries left.',
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
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get useAnotherAccount => 'Use a different account';

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

  @override
  String get classGroups => 'Class groups';

  @override
  String get joinWithCode => 'Join with a code';

  @override
  String get createGroup => 'Create a class group';

  @override
  String get createGroupHint =>
      'For CRs: enter your section\'s routine once and share the code.';

  @override
  String get imTheCr => 'I\'m the CR, create a group';

  @override
  String get roleCr => 'CR';

  @override
  String membersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String classesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString classes a week',
      one: '1 class a week',
      zero: 'No classes yet',
    );
    return '$_temp0';
  }

  @override
  String get joinTitle => 'Join your class group';

  @override
  String get joinSubtitle => 'Enter the 6-letter code from your CR.';

  @override
  String get joinCodeLabel => 'Join code';

  @override
  String get joinAction => 'Join group';

  @override
  String get alreadyMember => 'You\'re already in this group';

  @override
  String get openGroup => 'Open group';

  @override
  String get createSubtitle =>
      'You\'ll be the CR. Classmates join with a code and see the routine you enter.';

  @override
  String get sectionLabel => 'Section';

  @override
  String get sectionHint => 'e.g. A';

  @override
  String get semesterLabel => 'Semester';

  @override
  String get semesterHint => 'e.g. Fall 2026';

  @override
  String get createAction => 'Create group';

  @override
  String get editGroup => 'Edit group details';

  @override
  String get inviteTitle => 'Invite classmates';

  @override
  String get inviteHint => 'Share this code in your class Messenger group.';

  @override
  String get copyInvite => 'Copy invite';

  @override
  String get inviteCopied => 'Invite copied. Paste it in your class group.';

  @override
  String inviteMessage(String group, String app, String code) {
    return 'Join $group on $app: open the app, tap \"Join with a code\" and enter $code';
  }

  @override
  String get weeklyRoutine => 'Weekly routine';

  @override
  String get addClass => 'Add class';

  @override
  String get editClass => 'Edit class';

  @override
  String get noClassesYetCr =>
      'Add your section\'s classes. It takes a few minutes, once a semester.';

  @override
  String get noClassesYetMember => 'Your CR hasn\'t added classes yet.';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get leaveGroupTitle => 'Leave this group?';

  @override
  String get leaveGroupBody =>
      'Its classes disappear from your routine. You can join again with the code.';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteGroupTitle => 'Delete this group for everyone?';

  @override
  String get deleteGroupBody =>
      'The routine is removed for every student in the group. This can\'t be undone.';

  @override
  String get courseCodeLabel => 'Course code';

  @override
  String get courseCodeHint => 'e.g. CSE311';

  @override
  String get courseTitleLabel => 'Course title';

  @override
  String get teacherLabel => 'Teacher';

  @override
  String get roomLabel => 'Room';

  @override
  String get startsLabel => 'Starts';

  @override
  String get endsLabel => 'Ends';

  @override
  String get classTheory => 'Theory';

  @override
  String get classLab => 'Lab';

  @override
  String get saveAndAddAnother => 'Save and add another';

  @override
  String get deleteClass => 'Delete class';

  @override
  String get errorEndBeforeStart => 'It must end after it starts.';

  @override
  String get nextClass => 'Next class';

  @override
  String get nowInClass => 'Now';

  @override
  String startsInMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'in $minutesString min';
  }

  @override
  String startsInHours(int hours, int minutes) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'in $hoursString h $minutesString min';
  }

  @override
  String endsInMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'ends in $minutesString min';
  }

  @override
  String get todaysClasses => 'Today\'s classes';

  @override
  String get noClassesToday => 'No classes today';

  @override
  String get doneForToday => 'Done for today';

  @override
  String nextOn(String day) {
    return 'Next class: $day';
  }

  @override
  String get offlineNotice => 'Offline. Showing your saved routine.';

  @override
  String roomShort(String room) {
    return 'Room $room';
  }

  @override
  String get routineNoClassesDay => 'No classes on this day';

  @override
  String get errorGroupNotFound =>
      'No class group with this code at your university. Check the code with your CR.';

  @override
  String get errorNotCr => 'Only the CR can change this group.';

  @override
  String get errorGroupLimit =>
      'You\'re already in 10 class groups. Leave one to join another.';

  @override
  String get errorGroupFull => 'This class group is full.';

  @override
  String get errorCrCannotLeave =>
      'You\'re the only CR. Make someone else CR in Members first, or delete the group.';

  @override
  String get errorSlotLimit =>
      'This routine already has the most classes allowed.';

  @override
  String get deleteClassTitle => 'Delete this class for everyone?';

  @override
  String get reminders => 'Class reminders';

  @override
  String remindersOnValue(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min before';
  }

  @override
  String get remindersOff => 'Off';

  @override
  String get remindersSwitch => 'Remind me before each class';

  @override
  String get remindersSwitchHint => 'Works without internet.';

  @override
  String get remindBefore => 'When';

  @override
  String get courses => 'Courses';

  @override
  String get coursesHint => 'Turn off courses you don\'t attend.';

  @override
  String get noCoursesYet => 'Courses appear here once you join a class group.';

  @override
  String get notificationsBlocked =>
      'Notifications are off for this app. Turn them on in your phone\'s settings, then try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get exactAlarmTitle => 'Remind on time';

  @override
  String get exactAlarmHint =>
      'Without this, Android may show reminders a few minutes late.';

  @override
  String get allow => 'Allow';

  @override
  String get reminderPromptTitle => 'Never miss a class';

  @override
  String get reminderPromptBody =>
      'Get a notification 10 minutes before each class.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get notNow => 'Not now';

  @override
  String notificationTitle(String course, int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$course in $minutesString min';
  }

  @override
  String get notificationChannel => 'Class reminders';

  @override
  String get notificationChannelHint => 'A reminder before each class';

  @override
  String classesAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString classes added',
      one: 'Class added',
    );
    return '$_temp0';
  }

  @override
  String get daysLabel => 'Days';

  @override
  String get daysHint => 'Pick every day this class meets at this time.';

  @override
  String get errorPickDay => 'Pick at least one day.';

  @override
  String get changeCancelled => 'Cancelled';

  @override
  String get changeMoved => 'Changed';

  @override
  String get changeExtra => 'Extra class';

  @override
  String get cancelThisClass => 'Cancel this class';

  @override
  String get changeTimeOrRoom => 'Change day, time or room';

  @override
  String get undoChange => 'Undo change';

  @override
  String get removeExtraClass => 'Remove extra class';

  @override
  String get editWeeklyClass => 'Edit weekly class';

  @override
  String get addExtraClass => 'Add extra class';

  @override
  String cancelClassTitle(String course, String date) {
    return 'Cancel $course on $date?';
  }

  @override
  String get cancelClassBody =>
      'Classmates see it as cancelled, and its reminder is removed. The weekly routine stays the same.';

  @override
  String get noteLabel => 'Note for classmates (optional)';

  @override
  String get noteHint => 'e.g. The teacher is on leave';

  @override
  String get keepClass => 'Keep class';

  @override
  String get confirmCancel => 'Cancel class';

  @override
  String onlyThisDay(String date) {
    return 'Only for $date. The weekly routine stays the same.';
  }

  @override
  String get dateLabel => 'Date';

  @override
  String get upcomingChanges => 'Upcoming changes';

  @override
  String wasTime(String time) {
    return 'was $time';
  }

  @override
  String get changeSaved => 'Saved. Classmates see it when they open the app.';

  @override
  String get openGroupAction => 'Open class group';

  @override
  String get announcements => 'Announcements';

  @override
  String get postAction => 'Post';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String get announcementHint =>
      'Write to your class, e.g. Bring a calculator tomorrow';

  @override
  String get pinToTop => 'Pin to top';

  @override
  String get pinToTopHint =>
      'Stays first until you unpin it. Only one can be pinned.';

  @override
  String get pinAction => 'Pin';

  @override
  String get unpinAction => 'Unpin';

  @override
  String get pinnedLabel => 'Pinned';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteAnnouncementTitle =>
      'Delete this announcement for everyone?';

  @override
  String get noAnnouncements => 'No announcements yet.';

  @override
  String get noAnnouncementsCr =>
      'Post updates for your class here: quizzes, things to bring, room news.';

  @override
  String get announcementPosted =>
      'Posted. Classmates see it when they open the app.';

  @override
  String get newBadge => 'New';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min ago';
  }

  @override
  String timeHoursAgo(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString h ago';
  }

  @override
  String get timeYesterday => 'yesterday';

  @override
  String get errorAnnouncementGone => 'This announcement was already deleted.';

  @override
  String get pushChannel => 'Class updates';

  @override
  String get pushChannelHint => 'Changes and announcements from your CR';

  @override
  String get myCourses => 'My courses';

  @override
  String get myCoursesHint =>
      'Turn off courses you don\'t take in this section, e.g. if you joined only for a retake. Only your own routine and reminders change.';

  @override
  String coursesShown(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$shownString of $totalString courses in your routine';
  }

  @override
  String get members => 'Members';

  @override
  String get youLabel => 'You';

  @override
  String get makeCr => 'Make CR';

  @override
  String get makeMember => 'Make member';

  @override
  String get stepDown => 'Step down as CR';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String removeMemberTitle(String name) {
    return 'Remove $name from the group?';
  }

  @override
  String get removeMemberBody =>
      'They stop seeing this routine. They could join again with the code.';

  @override
  String get crHint =>
      'CRs edit the routine, post announcements and manage members. Up to 3 per group.';

  @override
  String get unnamedStudent => 'Student';

  @override
  String get errorCrLimit => 'A group can have at most 3 CRs.';

  @override
  String get errorLastCr => 'Make someone else CR first.';

  @override
  String get errorRemoveCr => 'Make them a member first, then remove them.';

  @override
  String get errorPersonalLimit =>
      'You already have the most personal classes allowed.';

  @override
  String get newSemester => 'Start new semester';

  @override
  String get newSemesterBody =>
      'This clears the weekly routine and its changes. Members, the join code and announcements stay, and classmates are told.';

  @override
  String get startAction => 'Start';

  @override
  String get personalClasses => 'Personal';

  @override
  String get addPersonalClass => 'Add personal class';

  @override
  String get editPersonalClass => 'Edit personal class';

  @override
  String get personalHint =>
      'Only you see these: tuition, a job, a lab with another section.';

  @override
  String get personalNameLabel => 'Name';

  @override
  String get personalNameHint => 'e.g. Tuition';

  @override
  String get personalDetailsLabel => 'Details';

  @override
  String get placeLabel => 'Place';

  @override
  String get addToRoutine => 'Add to your routine';

  @override
  String get extraClassHint => 'For your class group, one day only';

  @override
  String get deletePersonalTitle => 'Delete this personal class?';

  @override
  String get addAction => 'Add';

  @override
  String get editAction => 'Edit';

  @override
  String get batteryTitle => 'Reminders arriving late?';

  @override
  String batteryBody(String brand, String app) {
    return '$brand phones can stop apps in the background. Let this app run without battery limits: Settings → Apps → $app → Battery → Unrestricted (or No restrictions).';
  }

  @override
  String get openSettings => 'Open settings';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get sendFeedbackHint => 'Found a bug or have an idea? Tell us.';

  @override
  String get notVerified => 'Not verified';

  @override
  String get verifyWithUniEmail => 'Verify with university email';

  @override
  String get verifyHint =>
      'Get the Verified badge with a code sent to your university email.';

  @override
  String get chooseUniversity => 'Choose your university';

  @override
  String get chooseUniversityHint =>
      'You signed in without a university email, so choose your university. You show as not verified until you verify with a university email.';

  @override
  String get searchUniversity => 'Name, short name or city';

  @override
  String get universityPickerHint =>
      'Search by name, a short name like DIU, or city.';

  @override
  String get currentUniversity => 'Current';

  @override
  String get allUniversities => 'All universities';

  @override
  String universityMatches(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get noUniversityFound => 'No university found';

  @override
  String get noUniversityFoundHint =>
      'Check the spelling, or try a short name like DIU or the email domain.';

  @override
  String get askToAddUniversity => 'Ask us to add it';

  @override
  String get addUniversitySubject => 'Please add my university';

  @override
  String get universityLabel => 'University';

  @override
  String get changeAction => 'Change';

  @override
  String get verifiedNow => 'You\'re now a verified student';

  @override
  String get verifyTitle => 'Verify you\'re a student';

  @override
  String get verifySubtitle =>
      'Enter the email your university gave you. We\'ll send a 6-digit code to it.';

  @override
  String get errorEmailInUse =>
      'This email already has its own account. Sign out and sign in with it instead.';

  @override
  String get errorAlreadyVerified => 'You\'re already verified.';

  @override
  String get errorUniversityRequired =>
      'Choose your university first in your profile.';

  @override
  String get errorChooseUniversity => 'Choose your university to continue.';

  @override
  String get errorNotUniversityEmailVerify =>
      'This email isn\'t from a supported university. Use the email your university gave you.';

  @override
  String get changeUniversity => 'Change university';

  @override
  String get changeWithEmail => 'With my new university email';

  @override
  String get changeWithEmailHint => 'Stay verified at your new university';

  @override
  String get changeWithoutEmail => 'Without a university email';

  @override
  String get changeWithoutEmailHint =>
      'Pick it from the list; you\'ll show as not verified';

  @override
  String leaveVerifiedTitle(String university) {
    return 'Move to $university?';
  }

  @override
  String get leaveVerifiedBody =>
      'You\'ll show as not verified until you verify with an email from your new university. Your class groups stay.';

  @override
  String get changeUniversitySubtitle =>
      'Enter your email at your new university. We\'ll send a 6-digit code to it.';

  @override
  String get universityChanged => 'University changed';

  @override
  String get moveAction => 'Move';

  @override
  String movedToDay(String day) {
    return 'Moved to $day';
  }

  @override
  String movedFromDay(String day) {
    return 'Moved from $day';
  }

  @override
  String movedDayNotice(String from, String to) {
    return 'This week only: from $from to $to. The weekly routine stays the same.';
  }

  @override
  String get dayTapToChange => 'Tap to move it to another day';

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get testsAndDeadlines => 'Tests & deadlines';

  @override
  String get comingUp => 'Coming up';

  @override
  String get addTest => 'Add test or deadline';

  @override
  String get editTest => 'Edit test or deadline';

  @override
  String get noTestsYet =>
      'No tests or deadlines yet. Anyone in the group can add one.';

  @override
  String get testKindLabel => 'What is it?';

  @override
  String get kindClassTest => 'Class test';

  @override
  String get kindQuiz => 'Quiz';

  @override
  String get kindAssignment => 'Assignment';

  @override
  String get kindLabReport => 'Lab report';

  @override
  String get kindPresentation => 'Presentation';

  @override
  String get kindMidterm => 'Mid-term';

  @override
  String get kindFinal => 'Final exam';

  @override
  String get kindOther => 'Other';

  @override
  String get testTimeLabel => 'Time';

  @override
  String get testNoTime => 'No time';

  @override
  String get testAddTime => 'Add a time';

  @override
  String get testAddEnd => 'Add an end time';

  @override
  String get dueLabel => 'Due';

  @override
  String dueAt(String time) {
    return 'Due $time';
  }

  @override
  String get topicsLabel => 'Topics or details (optional)';

  @override
  String get topicsHint => 'e.g. Chapters 1–3, bring a calculator';

  @override
  String get testSaved => 'Saved. Classmates get a notification.';

  @override
  String get testDeleted => 'Deleted';

  @override
  String deleteTestTitle(String kind) {
    return 'Delete this $kind?';
  }

  @override
  String get deleteTestBody => 'It\'s removed for everyone in the group.';

  @override
  String addedBy(String name) {
    return 'Added by $name';
  }

  @override
  String get testOnlyOwnerHint => 'Only who added it or a CR can change it.';

  @override
  String reminderTestTomorrow(String kind, String course) {
    return 'Tomorrow: $kind · $course';
  }

  @override
  String reminderTestSoon(String kind, String course) {
    return '$kind soon · $course';
  }

  @override
  String reminderTestToday(String kind, String course) {
    return 'Today: $kind · $course';
  }

  @override
  String get errorAssessmentDate => 'Pick a date from today, within 6 months.';

  @override
  String get errorAssessmentLimit =>
      'This group already has the most upcoming tests and deadlines allowed.';

  @override
  String get errorAssessmentGone => 'This was already deleted.';

  @override
  String get errorNotAssessmentOwner =>
      'Only who added it or a CR can change it.';

  @override
  String get errorMoveDate => 'Pick a day from today, within 6 months.';
}
