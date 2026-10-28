// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VarsityKotha';

  @override
  String get navToday => 'Today';

  @override
  String get navRoutine => 'Routine';

  @override
  String get navProfile => 'Profile';

  @override
  String get navExplore => 'Explore';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSubtitle =>
      'Everything VarsityKotha does for you, in one place.';

  @override
  String get exploreYourTools => 'Your tools';

  @override
  String get exploreComingSoon => 'On the way';

  @override
  String get exploreRemindersHint => 'Before every class';

  @override
  String get exploreGroupsHint => 'Join or manage your sections';

  @override
  String get exploreIssuesHint => 'Issues you raised';

  @override
  String get busRoutesTitle => 'Bus routes';

  @override
  String get busRoutesBody =>
      'Your university\'s bus routes, stops and departure times, with the next bus from your stop.';

  @override
  String get busRoutesEmptyTitle => 'No bus routes yet';

  @override
  String get busRoutesEmptyBody =>
      'Your university\'s routes show here once your transport rep adds them.';

  @override
  String get busAddRoute => 'Add route';

  @override
  String get busToCampus => 'To campus';

  @override
  String get busFromCampus => 'From campus';

  @override
  String busNextFrom(String stop) {
    return 'Next bus from $stop';
  }

  @override
  String busNextAt(String time) {
    return 'Next: $time';
  }

  @override
  String get busNoMoreBuses => 'No more buses this week';

  @override
  String get busMyStop => 'My stop';

  @override
  String get busPickStop => 'Pick your stop to see your next bus';

  @override
  String get busChangeStop => 'Change my stop';

  @override
  String get busStopsTitle => 'Stops';

  @override
  String get busDepartures => 'Departures';

  @override
  String get busNoStops => 'No stops yet';

  @override
  String get busNoTrips => 'No departures this way yet';

  @override
  String get busHidden => 'Hidden';

  @override
  String get busEditRoute => 'Edit route';

  @override
  String get busEditStops => 'Edit stops';

  @override
  String get busEditTimetable => 'Edit timetable';

  @override
  String get busDeleteRoute => 'Delete route';

  @override
  String busDeleteRouteTitle(String name) {
    return 'Delete $name for everyone?';
  }

  @override
  String get busRouteName => 'Route name';

  @override
  String get busRouteNameHint => 'e.g. Route 4 · Mirpur';

  @override
  String get busColor => 'Color';

  @override
  String get busNotes => 'Notes (optional)';

  @override
  String get busNotesHint => 'e.g. No bus during exams';

  @override
  String get busShowRoute => 'Show this route';

  @override
  String get busShowRouteHint =>
      'Hidden routes are visible only to transport reps.';

  @override
  String get busAddStop => 'Add stop';

  @override
  String get busStopName => 'Stop name';

  @override
  String get busLandmark => 'Landmark (optional)';

  @override
  String get busToCampusMinutes => 'Minutes from the start, to campus';

  @override
  String get busFromCampusMinutes => 'Minutes after leaving campus';

  @override
  String get busMinutesHint =>
      'Leave empty if the bus doesn\'t stop here that way.';

  @override
  String get busStopsHint => 'From the far end to campus. Drag to reorder.';

  @override
  String get busAddDeparture => 'Add departure';

  @override
  String get busDepartsAt => 'Leaves at';

  @override
  String get busWeekdays => 'Days';

  @override
  String get busTripNote => 'Note (optional)';

  @override
  String get busSaved => 'Saved';

  @override
  String busMinutesValue(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min';
  }

  @override
  String get busEveryDay => 'Every day';

  @override
  String get busNotRep =>
      'Only your university\'s transport rep can change bus routes.';

  @override
  String get busRouteNotFound => 'This bus route was removed.';

  @override
  String get busOffline => 'Offline. Showing saved bus routes.';

  @override
  String busTripFirstStop(String stop) {
    return 'From $stop';
  }

  @override
  String get busSave => 'Save';

  @override
  String get busNameRequired => 'Give it a name.';

  @override
  String get busPickDay => 'Pick at least one day.';

  @override
  String get busEdit => 'Edit';

  @override
  String get busSetupTitle => 'Finish setting up this route';

  @override
  String get busSetupBody =>
      'Students can use the route once it has stops and departure times.';

  @override
  String get busSetupStops => 'Add the stops';

  @override
  String get busSetupTimes => 'Add departure times';

  @override
  String get busSetupMap => 'Place the stops on the map';

  @override
  String get busStart => 'Start';

  @override
  String busLegFrom(String stop) {
    return 'Minutes from $stop';
  }

  @override
  String busLegBackFrom(String stop) {
    return 'On the way back: minutes from $stop';
  }

  @override
  String get busFirstStopNote => 'The trip to campus starts here.';

  @override
  String get busLastStopNote => 'The trip back starts here.';

  @override
  String get busNoTime => 'No time';

  @override
  String busLegValue(int minutes) {
    return '+$minutes min';
  }

  @override
  String busTotalTrip(int minutes) {
    return '$minutes min to campus';
  }

  @override
  String get busLegHint =>
      'Leave empty if you don\'t know. Students then see “—” for this stop.';

  @override
  String get busSameWayBack => 'Same times on the way back';

  @override
  String get busSameWayBackHint =>
      'The way back takes the same time between stops, in reverse.';

  @override
  String get busQuickAddHint => 'Type a stop and press Enter';

  @override
  String get busPasteList => 'Paste a list';

  @override
  String get busPasteTitle => 'Paste stops';

  @override
  String get busPasteBody =>
      'One per line, or separated by commas, like in a transport notice. Text in brackets becomes the landmark.';

  @override
  String get busPasteFromClipboard => 'Paste';

  @override
  String busPasteAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count stops',
      one: 'Add 1 stop',
    );
    return '$_temp0';
  }

  @override
  String get busPasteNone => 'No stops found in this text yet.';

  @override
  String busTooManyStops(int max) {
    return 'A route can have at most $max stops.';
  }

  @override
  String busStopRemoved(String name) {
    return '$name removed';
  }

  @override
  String get busDepartureRemoved => 'Departure removed';

  @override
  String get busUndo => 'Undo';

  @override
  String get busRemoveStop => 'Remove stop';

  @override
  String get busEditStop => 'Edit stop';

  @override
  String get busDiscardTitle => 'Discard your changes?';

  @override
  String get busDiscardBody => 'You haven\'t saved them yet.';

  @override
  String get busDiscard => 'Discard';

  @override
  String get busKeepEditing => 'Keep editing';

  @override
  String get busTripTooLong =>
      'A trip can\'t be longer than 10 hours. Check the minutes.';

  @override
  String get busLocationNone => 'Not on the map yet';

  @override
  String get busLocationSet => 'On the map';

  @override
  String get busSetOnMap => 'Set on map';

  @override
  String get busChangeLocation => 'Change';

  @override
  String get busRemoveLocation => 'Remove from the map';

  @override
  String busPickerTitle(String stop) {
    return 'Place $stop';
  }

  @override
  String get busPickerHint => 'Move the map until the pin is on the stop.';

  @override
  String get busUseThisPlace => 'Use this place';

  @override
  String get busSearchPlace => 'Search for a place';

  @override
  String get busSearchNoResults =>
      'No places found. Try another name, or move the map.';

  @override
  String get busSearchFailed =>
      'Search isn\'t working right now. Move the map instead.';

  @override
  String get busMapTitle => 'Route map';

  @override
  String get busOpenMap => 'Open map';

  @override
  String busNotOnMap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops aren\'t on the map yet',
      one: '1 stop isn\'t on the map yet',
    );
    return '$_temp0';
  }

  @override
  String get busDirections => 'Directions';

  @override
  String get busSetMyStop => 'Set as my stop';

  @override
  String busStopNoTime(String stop) {
    return '$stop has no time listed.';
  }

  @override
  String busRouteLeaves(String stop, String time) {
    return 'The bus leaves $stop at $time.';
  }

  @override
  String get busNoTripsToCampus => 'No buses to campus on this route.';

  @override
  String get busNoTripsFromCampus => 'No buses from campus on this route.';

  @override
  String busLeavesFrom(String stop) {
    return 'When it leaves $stop';
  }

  @override
  String get busAddTimes => 'Add times';

  @override
  String get busAddAnotherTime => 'Add another time';

  @override
  String busAddDepartures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count departures',
      one: 'Add 1 departure',
    );
    return '$_temp0';
  }

  @override
  String get busPickTime => 'Add at least one time.';

  @override
  String busStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get busTimetableTitle => 'Timetable';

  @override
  String get busNoTimesYet => 'No times yet';

  @override
  String busDistanceM(int metres) {
    return '$metres m';
  }

  @override
  String busDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get busWhereAmI => 'Where am I';

  @override
  String busNearestStop(String stop, String distance) {
    return 'Nearest stop: $stop, $distance away';
  }

  @override
  String get busLocationServiceOff =>
      'Location is off on this phone. Turn it on to see where you are.';

  @override
  String get busLocationDenied =>
      'VarsityKotha can\'t use your location. You can allow it in Settings.';

  @override
  String get busOpenSettings => 'Settings';

  @override
  String get busFitRoute => 'Whole route';

  @override
  String get busLocationPrivate => 'Your location stays on your phone.';

  @override
  String get busUseMyLocation => 'Use my location';

  @override
  String get busFindingYou => 'Finding you…';

  @override
  String get busDriver => 'Driver';

  @override
  String get busDriverName => 'Driver\'s name (optional)';

  @override
  String get busDriverPhone => 'Driver\'s phone (optional)';

  @override
  String get busDriverPhoneHint => 'e.g. 01712345678';

  @override
  String get busCallDriver => 'Call driver';

  @override
  String busCallName(String name) {
    return 'Call $name';
  }

  @override
  String get busPhoneInvalid => 'Use a phone number like 01712345678.';

  @override
  String get teacherReviewsTitle => 'Teacher evaluations';

  @override
  String get teacherReviewsBody =>
      'Rate courses and teaching anonymously, to help classmates choose and help teachers improve.';

  @override
  String get rankingsTitle => 'University rankings';

  @override
  String get rankingsBody =>
      'How universities compare, rated by their own students: teaching, facilities, campus life and how fast issues get fixed.';

  @override
  String get visitCampusTitle => 'Visit other campuses';

  @override
  String get visitCampusBody =>
      'Look around other universities: their campus, clubs, events and what their students are talking about.';

  @override
  String get gotIt => 'Got it';

  @override
  String get comingSoonNote =>
      'We\'re building this. It will arrive in a future update.';

  @override
  String get cgpaTitle => 'CGPA calculator';

  @override
  String get cgpaHint => 'GPA, CGPA and targets';

  @override
  String get cgpaLabel => 'CGPA';

  @override
  String cgpaGpa(String gpa) {
    return 'GPA $gpa';
  }

  @override
  String cgpaCredits(String credits) {
    return '$credits credits';
  }

  @override
  String get cgpaCreditsEarned => 'Credits earned';

  @override
  String get cgpaLastSemester => 'Last semester';

  @override
  String get cgpaScaleUgc => 'UGC scale';

  @override
  String get cgpaScaleCustom => 'Custom scale';

  @override
  String get cgpaNoGrades => 'No grades yet';

  @override
  String cgpaCoursesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString courses',
      one: '1 course',
    );
    return '$_temp0';
  }

  @override
  String get cgpaSemesters => 'Semesters';

  @override
  String get cgpaAddSemester => 'Add semester';

  @override
  String get cgpaSemesterName => 'Semester name';

  @override
  String get cgpaSemesterHint => 'e.g. Spring 2026';

  @override
  String get cgpaRename => 'Rename';

  @override
  String get cgpaMoveUp => 'Move up';

  @override
  String get cgpaMoveDown => 'Move down';

  @override
  String get cgpaDeleteSemesterTitle => 'Delete this semester and its courses?';

  @override
  String get cgpaEmptyTitle => 'Track your CGPA';

  @override
  String get cgpaEmptyBody =>
      'Add your semesters and grades. Everything stays on this phone.';

  @override
  String get cgpaAddCourse => 'Add course';

  @override
  String get cgpaEditCourse => 'Edit course';

  @override
  String get cgpaCourseCode => 'Course code';

  @override
  String get cgpaCourseTitle => 'Course title (optional)';

  @override
  String get cgpaCreditsLabel => 'Credits';

  @override
  String get cgpaCreditsInvalid => 'Credits must be between 0.5 and 6.';

  @override
  String get cgpaCodeRequired => 'Enter a course code or title.';

  @override
  String get cgpaGradeLetter => 'Letter grade';

  @override
  String get cgpaGradeMarks => 'Marks';

  @override
  String get cgpaNotGraded => 'Not graded yet';

  @override
  String get cgpaMarksLabel => 'Marks out of 100';

  @override
  String cgpaMarksGives(String letter, String points) {
    return 'Grade: $letter ($points)';
  }

  @override
  String get cgpaMarksInvalid => 'Marks must be 0 to 100.';

  @override
  String get cgpaNotCounted => 'Not counted: retaken';

  @override
  String get cgpaFromRoutine => 'Add my routine\'s courses';

  @override
  String get cgpaFromRoutineHint => 'Your current courses, ready to grade.';

  @override
  String get cgpaTarget => 'Plan a target';

  @override
  String get cgpaTargetCgpa => 'Target CGPA';

  @override
  String get cgpaNextCredits => 'Credits left to take';

  @override
  String cgpaTargetNeeds(String gpa) {
    return 'You need a GPA of $gpa in those credits.';
  }

  @override
  String get cgpaTargetReached =>
      'You\'re already there. Keep passing to stay above it.';

  @override
  String cgpaTargetOut(String gpa) {
    return 'Not reachable: it would need a GPA of $gpa. Try more credits or a lower target.';
  }

  @override
  String get cgpaTargetInvalid => 'Enter a target CGPA and the credits left.';

  @override
  String get cgpaGradingScale => 'Grading scale';

  @override
  String get cgpaUseUgc => 'UGC uniform scale (4.00)';

  @override
  String get cgpaUseUgcHint => 'Most Bangladeshi universities use it.';

  @override
  String get cgpaUseCustom => 'My university\'s own scale';

  @override
  String get cgpaUseCustomHint =>
      'Set your own grades, points and mark ranges.';

  @override
  String get cgpaGradeShort => 'Grade';

  @override
  String get cgpaPoints => 'Points';

  @override
  String get cgpaMinMarks => 'From marks';

  @override
  String get cgpaAddGrade => 'Add grade';

  @override
  String get cgpaRetakeRule => 'Retaken courses';

  @override
  String get cgpaRetakeBest => 'Best attempt counts';

  @override
  String get cgpaRetakeBestHint =>
      'The usual rule: a better grade replaces the earlier one.';

  @override
  String get cgpaRetakeLatest => 'Latest attempt counts';

  @override
  String get cgpaRetakeAll => 'Every attempt counts';

  @override
  String get cgpaRetakeHint => 'Attempts are matched by course code.';

  @override
  String get cgpaProblemEmpty => 'Add at least one grade.';

  @override
  String get cgpaProblemLetter => 'Every grade needs its own name.';

  @override
  String get cgpaProblemPoints => 'Points must be 0 to 5.';

  @override
  String get cgpaProblemMarks =>
      'Each grade needs its own starting mark, 0 to 100.';

  @override
  String get cgpaProblemZero => 'One grade must start at 0 marks.';

  @override
  String get cgpaProblemOrder => 'More marks can\'t give fewer points.';

  @override
  String get cgpaClearAll => 'Clear everything';

  @override
  String get cgpaClearTitle => 'Delete all semesters and grades on this phone?';

  @override
  String get cgpaSave => 'Save';

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
  String get deleteAccountUnderstand => 'I understand this can\'t be undone';

  @override
  String get photoAdd => 'Add a photo';

  @override
  String get photoChange => 'Change photo';

  @override
  String get photoTake => 'Take a photo';

  @override
  String get photoGallery => 'Choose from gallery';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get photoRemoved => 'Photo removed';

  @override
  String get photoNotAllowed => 'This photo can\'t be used. Try another one.';

  @override
  String get photoCheckDown =>
      'Photos can\'t be checked right now. Try again later.';

  @override
  String get photoTooLarge => 'This photo is too large.';

  @override
  String get photoInvalid => 'This file isn\'t a photo we can use.';

  @override
  String get photoWhoSees =>
      'Classmates in your class groups see your photo. Campus Voice never shows it.';

  @override
  String get photoGoogleHint => 'Your Google photo shows until you add one.';

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
  String get findClass => 'Find your class';

  @override
  String get findClassHint => 'Department, batch, course code or teacher';

  @override
  String get findClassIntro =>
      'Search your university\'s class routines. Join a whole section, or just the courses you take.';

  @override
  String get findClassEmptyTitle => 'No class found';

  @override
  String get findClassEmptyBody =>
      'Try a course code (CSE 311), or department and batch. Or ask your CR for the join code.';

  @override
  String get findClassOffline => 'Searching needs an internet connection.';

  @override
  String get findClassJoined => 'Joined';

  @override
  String findClassCr(String name) {
    return 'CR: $name';
  }

  @override
  String get findClassMore => 'Show more';

  @override
  String get findClassHaveCode => 'Have a join code?';

  @override
  String get previewPickHint =>
      'Untick the courses you don\'t take. You\'ll only see the ones you keep.';

  @override
  String get previewNoClasses => 'No classes in this routine yet.';

  @override
  String get joinWholeSection => 'Join whole section';

  @override
  String addSelectedCourses(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $countString courses',
      one: 'Add 1 course',
    );
    return '$_temp0';
  }

  @override
  String get saveMyCourses => 'Save my courses';

  @override
  String get addedToRoutine => 'Added to your routine';

  @override
  String get similarGroupsTitle => 'This class may already exist';

  @override
  String get similarGroupsBody =>
      'Join it instead, so your class keeps one routine.';

  @override
  String get joinInstead => 'Join instead';

  @override
  String findableTitle(String university) {
    return 'Findable at $university';
  }

  @override
  String get findableBody =>
      'Students of your university can find this class by search. Off: only people with the join code can join.';

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
  String get shareInvite => 'Share invite';

  @override
  String get inviteCopied => 'Invite copied. Paste it in your class group.';

  @override
  String inviteMessage(String group, String app, String link, String code) {
    return 'Join $group on $app: $link\nOr open the app, tap \"Join with a code\" and enter $code';
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

  @override
  String get navCampus => 'Campus';

  @override
  String get voiceTitle => 'Campus Voice';

  @override
  String get voiceSortTrending => 'Trending';

  @override
  String get voiceSortNew => 'New';

  @override
  String get voiceSortSolved => 'Solved';

  @override
  String get voiceAllCategories => 'All';

  @override
  String get voiceSearchHint => 'Search issues';

  @override
  String get voiceRaiseIssue => 'Raise issue';

  @override
  String get voiceMyIssues => 'My issues';

  @override
  String get voiceSafetyReports => 'Safety reports';

  @override
  String get voiceEmptyFeed => 'No issues here yet';

  @override
  String get voiceEmptyFeedHint =>
      'Something wrong on campus? Raise it. You stay anonymous.';

  @override
  String get voiceEmptySearch => 'No issues match your search';

  @override
  String get voiceEmptyMine => 'You haven\'t raised an issue yet';

  @override
  String get voiceEmptyMineHint =>
      'Issues you raise show here, including ones under review.';

  @override
  String get voiceCatAcademic => 'Academic';

  @override
  String get voiceCatHostel => 'Hostel';

  @override
  String get voiceCatTransport => 'Transport';

  @override
  String get voiceCatFacilities => 'Facilities';

  @override
  String get voiceCatSafety => 'Safety';

  @override
  String get voiceCatAdministration => 'Administration';

  @override
  String get voiceCatFood => 'Food';

  @override
  String get voiceCatIt => 'IT / Wi-Fi';

  @override
  String get voiceCatOther => 'Other';

  @override
  String get voiceStatusOpen => 'Open';

  @override
  String get voiceStatusAcknowledged => 'Acknowledged';

  @override
  String get voiceStatusInProgress => 'In progress';

  @override
  String get voiceStatusSolved => 'Solved';

  @override
  String get voiceStatusRejected => 'Rejected';

  @override
  String get voiceUnderReview => 'Under review';

  @override
  String get voiceRemoved => 'Removed';

  @override
  String get voiceHiddenBadge => 'Hidden for review';

  @override
  String get voicePrivate => 'Private';

  @override
  String get voiceAnonymous => 'Anonymous';

  @override
  String get voiceYou => 'You';

  @override
  String voiceHandle(String handle) {
    return 'Student $handle';
  }

  @override
  String get voiceAuthorTag => 'Author';

  @override
  String get voiceDeletedAccount => 'Deleted account';

  @override
  String get voiceOfficial => 'Official';

  @override
  String get voiceMeToo => 'Me too';

  @override
  String voiceMeTooSemantics(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Me too, $countString students';
  }

  @override
  String get voiceFollow => 'Follow';

  @override
  String get voiceFollowing => 'Following';

  @override
  String get voiceComments => 'Comments';

  @override
  String get voiceStatusHistory => 'Status';

  @override
  String get voiceRaised => 'Raised';

  @override
  String voiceStepBy(String who, String when) {
    return '$who · $when';
  }

  @override
  String get voiceActorAuthor => 'The author';

  @override
  String get voiceActorModerator => 'Moderator';

  @override
  String get voiceActorSystem => 'VarsityKotha';

  @override
  String get voiceHeldNotice =>
      'Only you can see this while it\'s checked. It usually takes less than a day.';

  @override
  String get voiceHeldPersonalInfo =>
      'It may contain a phone number, email, link or ID number.';

  @override
  String get voiceHeldLanguage => 'It may contain words that aren\'t allowed.';

  @override
  String get voiceHeldPhoto => 'A moderator checks a photo in this post first.';

  @override
  String get voiceHeldUnverified =>
      'Posts from accounts without a verified university email are checked first.';

  @override
  String voiceRemovedNotice(String reason) {
    return 'Removed by moderators: $reason';
  }

  @override
  String get voiceRemovedByYou => 'You deleted this issue.';

  @override
  String get voiceHiddenNotice => 'Hidden while moderators look at reports.';

  @override
  String get voicePrivateNotice =>
      'Private: only you, moderators and your university\'s officials can see this.';

  @override
  String get voiceCommentHint => 'Add a comment';

  @override
  String voiceCommentAs(String who) {
    return 'Commenting as $who';
  }

  @override
  String get voiceCommentAnonymously => 'Anonymously';

  @override
  String get voiceCommentWithName => 'With my name';

  @override
  String get voiceNoComments => 'No comments yet';

  @override
  String get voiceCommentRemoved => 'This comment was removed.';

  @override
  String get voiceCommentUnderReview =>
      'Only you can see this comment while it\'s checked.';

  @override
  String get voiceLoadMore => 'Load more';

  @override
  String get voiceSend => 'Send';

  @override
  String get voiceReport => 'Report';

  @override
  String get voiceReopen => 'Reopen';

  @override
  String get voiceReopenTitle => 'Reopen this issue?';

  @override
  String get voiceReopenHint => 'Tell officials what\'s still wrong';

  @override
  String get voiceDeleteIssueTitle => 'Delete this issue?';

  @override
  String get voiceDeleteIssueBody =>
      'It disappears for everyone. This can\'t be undone.';

  @override
  String get voiceDeleteCommentTitle => 'Delete this comment?';

  @override
  String get voiceEditIssue => 'Edit issue';

  @override
  String get voiceEditWindow => 'You can edit for 60 minutes after posting.';

  @override
  String get voiceReportTitle => 'Why are you reporting this?';

  @override
  String get voiceReportSpam => 'Spam';

  @override
  String get voiceReportAbuse => 'Abusive or hateful';

  @override
  String get voiceReportPersonalInfo =>
      'Shares someone\'s personal information';

  @override
  String get voiceReportFalseInfo => 'False information';

  @override
  String get voiceReportInappropriate => 'Inappropriate';

  @override
  String get voiceReportOther => 'Something else';

  @override
  String get voiceReportDetails => 'Details (optional)';

  @override
  String get voiceReportSent => 'Thanks. Moderators will look at it.';

  @override
  String get voiceReportAnon => 'Reports are anonymous.';

  @override
  String get voiceChangeStatus => 'Change status';

  @override
  String get voiceStatusNote => 'Note for students';

  @override
  String get voiceStatusNoteHint => 'What\'s being done, or why';

  @override
  String get voiceNoteRequired => 'Say why it\'s rejected.';

  @override
  String get voiceOfficialReply => 'Official reply';

  @override
  String get voiceOfficialReplyHint =>
      'Write a public reply. Your title and name are shown.';

  @override
  String get voiceStatusUpdated => 'Status updated';

  @override
  String get voiceReplyPosted => 'Reply posted';

  @override
  String get voiceOfficialBadge => 'University official';

  @override
  String get voiceNewTitle => 'Raise an issue';

  @override
  String voiceStepOf(int step) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);

    return 'Step $stepString of 3';
  }

  @override
  String get voiceStepCategory => 'What is it about?';

  @override
  String get voiceSafetyNote =>
      'Safety reports are private: only moderators and your university\'s officials see them.';

  @override
  String get voiceStepDetails => 'Tell us what\'s wrong';

  @override
  String get voiceTitleLabel => 'Title';

  @override
  String get voiceTitleHint => 'e.g. No water in Hall 2 since Sunday';

  @override
  String get voiceBodyLabel => 'Details';

  @override
  String get voiceBodyHint =>
      'What happens, where and since when. Don\'t include names, phone numbers or roll numbers.';

  @override
  String get voicePlaceLabel => 'Place (optional)';

  @override
  String get voicePlaceHint => 'e.g. Library, 3rd floor';

  @override
  String get voicePhotosLabel => 'Photos';

  @override
  String get voiceAddPhoto => 'Add photo';

  @override
  String get voicePhotosHint =>
      'Up to 4. Location and phone details are removed.';

  @override
  String voicePhoto(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Photo $nString';
  }

  @override
  String get voiceRemovePhoto => 'Remove photo';

  @override
  String voiceAtLeast(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Write at least $nString characters.';
  }

  @override
  String get voiceStepReview => 'Before you post';

  @override
  String get voiceSimilarTitle => 'Similar issues';

  @override
  String get voiceSimilarHint =>
      'If one of these is the same, tap Me too there instead of posting again.';

  @override
  String get voiceNoSimilar => 'No similar issues found.';

  @override
  String get voicePostAnon => 'Post anonymously';

  @override
  String get voicePostAnonHint => 'Your name, email and class are never shown.';

  @override
  String get voicePostNamedHint => 'Students will see your name on this issue.';

  @override
  String get voiceHowAnonymity => 'How anonymity works';

  @override
  String get voicePost => 'Post';

  @override
  String get voiceNext => 'Next';

  @override
  String get voiceBack => 'Back';

  @override
  String get voicePosted => 'Issue posted';

  @override
  String get voicePostedHeld =>
      'Posted. Others will see it after a quick check.';

  @override
  String get voiceUploading => 'Uploading photos…';

  @override
  String get voiceDraftKept => 'Your draft is kept on this phone.';

  @override
  String get voiceOfflineAction =>
      'You\'re offline. Try again when you\'re connected.';

  @override
  String get voiceAnonTitle => 'How anonymity works';

  @override
  String get voiceAnonIntro =>
      'Campus Voice is built so you can speak up safely.';

  @override
  String get voiceAnon1 =>
      'Your name, email and class are never shown on anonymous posts.';

  @override
  String get voiceAnon2 =>
      'Who wrote what is stored separately. No screen, staff member or university official can see it, in the app or in our admin panel.';

  @override
  String get voiceAnon3 =>
      'Your handle (like “Student 7KQF”) is different on every issue.';

  @override
  String get voiceAnon4 =>
      'Photos are cleaned: location and phone details are removed.';

  @override
  String get voiceAnon5 => 'Times are shown roughly, not to the minute.';

  @override
  String get voiceAnon6 =>
      'Breaking the rules (threats, naming people, spam) can get your posting blocked, without anyone seeing who you are.';

  @override
  String get voiceAnon7 =>
      'What you write can still give you away. Don\'t include your name, roll number or details only you would know. Anyone can screenshot a public post.';

  @override
  String get voiceAnon8 =>
      'Safety reports are private: only moderators and your university\'s officials see them.';

  @override
  String get errorFeatureDisabled => 'Campus Voice isn\'t open yet.';

  @override
  String get errorVoiceBanned =>
      'You can\'t post, comment or vote right now because of a rules break.';

  @override
  String errorVoiceBannedUntil(String date) {
    return 'You can\'t post, comment or vote until $date because of a rules break.';
  }

  @override
  String get errorIssueNotFound => 'This issue isn\'t available.';

  @override
  String get errorCommentNotFound => 'This comment isn\'t available.';

  @override
  String get errorUploadNotFound =>
      'A photo didn\'t finish uploading. Remove it and add it again.';

  @override
  String get errorImageInvalid => 'That file isn\'t a photo we can use.';

  @override
  String get errorImageTooLarge => 'That photo is too large.';

  @override
  String get errorPhotoNotAllowed =>
      'This photo can\'t be posted. Choose another photo.';

  @override
  String get voicePhotoRefused => 'Can\'t be posted';

  @override
  String get errorEditWindowClosed =>
      'Issues can only be edited in the first 60 minutes.';

  @override
  String get errorReopenNotAllowed =>
      'Only solved issues can be reopened, within 30 days.';

  @override
  String get errorIssueClosed =>
      'This issue was removed, so it can\'t get new comments.';

  @override
  String get errorCannotVoteOwn =>
      'You raised this issue, so it already counts you.';

  @override
  String get errorAlreadyReported => 'You already reported this.';

  @override
  String get errorStatusChangeInvalid => 'That status change isn\'t possible.';

  @override
  String get errorNoteRequired => 'Add a note saying why.';

  @override
  String get voiceFromGallery => 'Choose from gallery';

  @override
  String get voiceTakePhoto => 'Take a photo';

  @override
  String get voiceHeldModerator => 'Moderators hid this while they look at it.';
}
