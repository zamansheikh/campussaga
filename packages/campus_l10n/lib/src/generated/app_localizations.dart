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
  /// **'VarsityKotha'**
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

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything VarsityKotha does for you, in one place.'**
  String get exploreSubtitle;

  /// No description provided for @exploreYourTools.
  ///
  /// In en, this message translates to:
  /// **'Your tools'**
  String get exploreYourTools;

  /// No description provided for @exploreComingSoon.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get exploreComingSoon;

  /// No description provided for @exploreRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'Before every class'**
  String get exploreRemindersHint;

  /// No description provided for @exploreGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'Join or manage your sections'**
  String get exploreGroupsHint;

  /// No description provided for @exploreIssuesHint.
  ///
  /// In en, this message translates to:
  /// **'Your posts, questions, polls and issues'**
  String get exploreIssuesHint;

  /// No description provided for @busRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bus routes'**
  String get busRoutesTitle;

  /// No description provided for @busRoutesBody.
  ///
  /// In en, this message translates to:
  /// **'Your university\'s bus routes, stops and departure times, with the next bus from your stop.'**
  String get busRoutesBody;

  /// No description provided for @busRoutesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bus routes yet'**
  String get busRoutesEmptyTitle;

  /// No description provided for @busRoutesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your university\'s routes show here once your transport rep adds them.'**
  String get busRoutesEmptyBody;

  /// No description provided for @busAddRoute.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get busAddRoute;

  /// No description provided for @busToCampus.
  ///
  /// In en, this message translates to:
  /// **'To campus'**
  String get busToCampus;

  /// No description provided for @busFromCampus.
  ///
  /// In en, this message translates to:
  /// **'From campus'**
  String get busFromCampus;

  /// No description provided for @busNextFrom.
  ///
  /// In en, this message translates to:
  /// **'Next bus from {stop}'**
  String busNextFrom(String stop);

  /// No description provided for @busNextAt.
  ///
  /// In en, this message translates to:
  /// **'Next: {time}'**
  String busNextAt(String time);

  /// No description provided for @busNoMoreBuses.
  ///
  /// In en, this message translates to:
  /// **'No more buses this week'**
  String get busNoMoreBuses;

  /// No description provided for @busMyStop.
  ///
  /// In en, this message translates to:
  /// **'My stop'**
  String get busMyStop;

  /// No description provided for @busPickStop.
  ///
  /// In en, this message translates to:
  /// **'Pick your stop to see your next bus'**
  String get busPickStop;

  /// No description provided for @busChangeStop.
  ///
  /// In en, this message translates to:
  /// **'Change my stop'**
  String get busChangeStop;

  /// No description provided for @busStopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get busStopsTitle;

  /// No description provided for @busDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get busDepartures;

  /// No description provided for @busNoStops.
  ///
  /// In en, this message translates to:
  /// **'No stops yet'**
  String get busNoStops;

  /// No description provided for @busNoTrips.
  ///
  /// In en, this message translates to:
  /// **'No departures this way yet'**
  String get busNoTrips;

  /// No description provided for @busHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get busHidden;

  /// No description provided for @busEditRoute.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get busEditRoute;

  /// No description provided for @busEditStops.
  ///
  /// In en, this message translates to:
  /// **'Edit stops'**
  String get busEditStops;

  /// No description provided for @busEditTimetable.
  ///
  /// In en, this message translates to:
  /// **'Edit timetable'**
  String get busEditTimetable;

  /// No description provided for @busDeleteRoute.
  ///
  /// In en, this message translates to:
  /// **'Delete route'**
  String get busDeleteRoute;

  /// No description provided for @busDeleteRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} for everyone?'**
  String busDeleteRouteTitle(String name);

  /// No description provided for @busRouteName.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get busRouteName;

  /// No description provided for @busRouteNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Route 4 · Mirpur'**
  String get busRouteNameHint;

  /// No description provided for @busColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get busColor;

  /// No description provided for @busNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get busNotes;

  /// No description provided for @busNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. No bus during exams'**
  String get busNotesHint;

  /// No description provided for @busShowRoute.
  ///
  /// In en, this message translates to:
  /// **'Show this route'**
  String get busShowRoute;

  /// No description provided for @busShowRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden routes are visible only to transport reps.'**
  String get busShowRouteHint;

  /// No description provided for @busAddStop.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get busAddStop;

  /// No description provided for @busStopName.
  ///
  /// In en, this message translates to:
  /// **'Stop name'**
  String get busStopName;

  /// No description provided for @busLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark (optional)'**
  String get busLandmark;

  /// No description provided for @busToCampusMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes from the start, to campus'**
  String get busToCampusMinutes;

  /// No description provided for @busFromCampusMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes after leaving campus'**
  String get busFromCampusMinutes;

  /// No description provided for @busMinutesHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if the bus doesn\'t stop here that way.'**
  String get busMinutesHint;

  /// No description provided for @busStopsHint.
  ///
  /// In en, this message translates to:
  /// **'From the far end to campus. Drag to reorder.'**
  String get busStopsHint;

  /// No description provided for @busAddDeparture.
  ///
  /// In en, this message translates to:
  /// **'Add departure'**
  String get busAddDeparture;

  /// No description provided for @busDepartsAt.
  ///
  /// In en, this message translates to:
  /// **'Leaves at'**
  String get busDepartsAt;

  /// No description provided for @busWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get busWeekdays;

  /// No description provided for @busTripNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get busTripNote;

  /// No description provided for @busSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get busSaved;

  /// No description provided for @busMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String busMinutesValue(int minutes);

  /// No description provided for @busEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get busEveryDay;

  /// No description provided for @busNotRep.
  ///
  /// In en, this message translates to:
  /// **'Only your university\'s transport rep can change bus routes.'**
  String get busNotRep;

  /// No description provided for @busRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'This bus route was removed.'**
  String get busRouteNotFound;

  /// No description provided for @busOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing saved bus routes.'**
  String get busOffline;

  /// No description provided for @busTripFirstStop.
  ///
  /// In en, this message translates to:
  /// **'From {stop}'**
  String busTripFirstStop(String stop);

  /// No description provided for @busSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get busSave;

  /// No description provided for @busNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name.'**
  String get busNameRequired;

  /// No description provided for @busPickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get busPickDay;

  /// No description provided for @busEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get busEdit;

  /// No description provided for @busSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up this route'**
  String get busSetupTitle;

  /// No description provided for @busSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Students can use the route once it has stops and departure times.'**
  String get busSetupBody;

  /// No description provided for @busSetupStops.
  ///
  /// In en, this message translates to:
  /// **'Add the stops'**
  String get busSetupStops;

  /// No description provided for @busSetupTimes.
  ///
  /// In en, this message translates to:
  /// **'Add departure times'**
  String get busSetupTimes;

  /// No description provided for @busSetupMap.
  ///
  /// In en, this message translates to:
  /// **'Place the stops on the map'**
  String get busSetupMap;

  /// No description provided for @busStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get busStart;

  /// No description provided for @busLegFrom.
  ///
  /// In en, this message translates to:
  /// **'Minutes from {stop}'**
  String busLegFrom(String stop);

  /// No description provided for @busLegBackFrom.
  ///
  /// In en, this message translates to:
  /// **'On the way back: minutes from {stop}'**
  String busLegBackFrom(String stop);

  /// No description provided for @busFirstStopNote.
  ///
  /// In en, this message translates to:
  /// **'The trip to campus starts here.'**
  String get busFirstStopNote;

  /// No description provided for @busLastStopNote.
  ///
  /// In en, this message translates to:
  /// **'The trip back starts here.'**
  String get busLastStopNote;

  /// No description provided for @busNoTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get busNoTime;

  /// No description provided for @busLegValue.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min'**
  String busLegValue(int minutes);

  /// No description provided for @busTotalTrip.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min to campus'**
  String busTotalTrip(int minutes);

  /// No description provided for @busLegHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if you don\'t know. Students then see “—” for this stop.'**
  String get busLegHint;

  /// No description provided for @busSameWayBack.
  ///
  /// In en, this message translates to:
  /// **'Same times on the way back'**
  String get busSameWayBack;

  /// No description provided for @busSameWayBackHint.
  ///
  /// In en, this message translates to:
  /// **'The way back takes the same time between stops, in reverse.'**
  String get busSameWayBackHint;

  /// No description provided for @busQuickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Type a stop and press Enter'**
  String get busQuickAddHint;

  /// No description provided for @busPasteList.
  ///
  /// In en, this message translates to:
  /// **'Paste a list'**
  String get busPasteList;

  /// No description provided for @busPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste stops'**
  String get busPasteTitle;

  /// No description provided for @busPasteBody.
  ///
  /// In en, this message translates to:
  /// **'One per line, or separated by commas, like in a transport notice. Text in brackets becomes the landmark.'**
  String get busPasteBody;

  /// No description provided for @busPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get busPasteFromClipboard;

  /// No description provided for @busPasteAdd.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 stop} other{Add {count} stops}}'**
  String busPasteAdd(int count);

  /// No description provided for @busPasteNone.
  ///
  /// In en, this message translates to:
  /// **'No stops found in this text yet.'**
  String get busPasteNone;

  /// No description provided for @busTooManyStops.
  ///
  /// In en, this message translates to:
  /// **'A route can have at most {max} stops.'**
  String busTooManyStops(int max);

  /// No description provided for @busStopRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String busStopRemoved(String name);

  /// No description provided for @busDepartureRemoved.
  ///
  /// In en, this message translates to:
  /// **'Departure removed'**
  String get busDepartureRemoved;

  /// No description provided for @busUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get busUndo;

  /// No description provided for @busRemoveStop.
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get busRemoveStop;

  /// No description provided for @busEditStop.
  ///
  /// In en, this message translates to:
  /// **'Edit stop'**
  String get busEditStop;

  /// No description provided for @busDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get busDiscardTitle;

  /// No description provided for @busDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved them yet.'**
  String get busDiscardBody;

  /// No description provided for @busDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get busDiscard;

  /// No description provided for @busKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get busKeepEditing;

  /// No description provided for @busTripTooLong.
  ///
  /// In en, this message translates to:
  /// **'A trip can\'t be longer than 10 hours. Check the minutes.'**
  String get busTripTooLong;

  /// No description provided for @busLocationNone.
  ///
  /// In en, this message translates to:
  /// **'Not on the map yet'**
  String get busLocationNone;

  /// No description provided for @busLocationSet.
  ///
  /// In en, this message translates to:
  /// **'On the map'**
  String get busLocationSet;

  /// No description provided for @busSetOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set on map'**
  String get busSetOnMap;

  /// No description provided for @busChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get busChangeLocation;

  /// No description provided for @busRemoveLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove from the map'**
  String get busRemoveLocation;

  /// No description provided for @busPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Place {stop}'**
  String busPickerTitle(String stop);

  /// No description provided for @busPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map until the pin is on the stop.'**
  String get busPickerHint;

  /// No description provided for @busUseThisPlace.
  ///
  /// In en, this message translates to:
  /// **'Use this place'**
  String get busUseThisPlace;

  /// No description provided for @busSearchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get busSearchPlace;

  /// No description provided for @busSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places found. Try another name, or move the map.'**
  String get busSearchNoResults;

  /// No description provided for @busSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t working right now. Move the map instead.'**
  String get busSearchFailed;

  /// No description provided for @busMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get busMapTitle;

  /// No description provided for @busOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get busOpenMap;

  /// No description provided for @busNotOnMap.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop isn\'t on the map yet} other{{count} stops aren\'t on the map yet}}'**
  String busNotOnMap(int count);

  /// No description provided for @busDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get busDirections;

  /// No description provided for @busSetMyStop.
  ///
  /// In en, this message translates to:
  /// **'Set as my stop'**
  String get busSetMyStop;

  /// No description provided for @busStopNoTime.
  ///
  /// In en, this message translates to:
  /// **'{stop} has no time listed.'**
  String busStopNoTime(String stop);

  /// No description provided for @busRouteLeaves.
  ///
  /// In en, this message translates to:
  /// **'The bus leaves {stop} at {time}.'**
  String busRouteLeaves(String stop, String time);

  /// No description provided for @busNoTripsToCampus.
  ///
  /// In en, this message translates to:
  /// **'No buses to campus on this route.'**
  String get busNoTripsToCampus;

  /// No description provided for @busNoTripsFromCampus.
  ///
  /// In en, this message translates to:
  /// **'No buses from campus on this route.'**
  String get busNoTripsFromCampus;

  /// No description provided for @busLeavesFrom.
  ///
  /// In en, this message translates to:
  /// **'When it leaves {stop}'**
  String busLeavesFrom(String stop);

  /// No description provided for @busAddTimes.
  ///
  /// In en, this message translates to:
  /// **'Add times'**
  String get busAddTimes;

  /// No description provided for @busAddAnotherTime.
  ///
  /// In en, this message translates to:
  /// **'Add another time'**
  String get busAddAnotherTime;

  /// No description provided for @busAddDepartures.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 departure} other{Add {count} departures}}'**
  String busAddDepartures(int count);

  /// No description provided for @busPickTime.
  ///
  /// In en, this message translates to:
  /// **'Add at least one time.'**
  String get busPickTime;

  /// No description provided for @busStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop} other{{count} stops}}'**
  String busStopsCount(int count);

  /// No description provided for @busTimetableTitle.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get busTimetableTitle;

  /// No description provided for @busNoTimesYet.
  ///
  /// In en, this message translates to:
  /// **'No times yet'**
  String get busNoTimesYet;

  /// No description provided for @busDistanceM.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String busDistanceM(int metres);

  /// No description provided for @busDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String busDistanceKm(String km);

  /// No description provided for @busWhereAmI.
  ///
  /// In en, this message translates to:
  /// **'Where am I'**
  String get busWhereAmI;

  /// No description provided for @busNearestStop.
  ///
  /// In en, this message translates to:
  /// **'Nearest stop: {stop}, {distance} away'**
  String busNearestStop(String stop, String distance);

  /// No description provided for @busLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off on this phone. Turn it on to see where you are.'**
  String get busLocationServiceOff;

  /// No description provided for @busLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'VarsityKotha can\'t use your location. You can allow it in Settings.'**
  String get busLocationDenied;

  /// No description provided for @busOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get busOpenSettings;

  /// No description provided for @busFitRoute.
  ///
  /// In en, this message translates to:
  /// **'Whole route'**
  String get busFitRoute;

  /// No description provided for @busLocationPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your location stays on your phone.'**
  String get busLocationPrivate;

  /// No description provided for @busUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get busUseMyLocation;

  /// No description provided for @busFindingYou.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get busFindingYou;

  /// No description provided for @busDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get busDriver;

  /// No description provided for @busDriverName.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s name (optional)'**
  String get busDriverName;

  /// No description provided for @busDriverPhone.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s phone (optional)'**
  String get busDriverPhone;

  /// No description provided for @busDriverPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 01712345678'**
  String get busDriverPhoneHint;

  /// No description provided for @busCallDriver.
  ///
  /// In en, this message translates to:
  /// **'Call driver'**
  String get busCallDriver;

  /// No description provided for @busCallName.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String busCallName(String name);

  /// No description provided for @busPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a phone number like 01712345678.'**
  String get busPhoneInvalid;

  /// No description provided for @teacherReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher evaluations'**
  String get teacherReviewsTitle;

  /// No description provided for @teacherReviewsBody.
  ///
  /// In en, this message translates to:
  /// **'Rate courses and teaching anonymously, to help classmates choose and help teachers improve.'**
  String get teacherReviewsBody;

  /// No description provided for @rankingsTitle.
  ///
  /// In en, this message translates to:
  /// **'University rankings'**
  String get rankingsTitle;

  /// No description provided for @rankingsBody.
  ///
  /// In en, this message translates to:
  /// **'How universities compare, rated by their own students: teaching, facilities, campus life and how fast issues get fixed.'**
  String get rankingsBody;

  /// No description provided for @visitCampusTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit other campuses'**
  String get visitCampusTitle;

  /// No description provided for @visitCampusBody.
  ///
  /// In en, this message translates to:
  /// **'Look around other universities: their campus, clubs, events and what their students are talking about.'**
  String get visitCampusBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @comingSoonNote.
  ///
  /// In en, this message translates to:
  /// **'We\'re building this. It will arrive in a future update.'**
  String get comingSoonNote;

  /// No description provided for @cgpaTitle.
  ///
  /// In en, this message translates to:
  /// **'CGPA calculator'**
  String get cgpaTitle;

  /// No description provided for @cgpaHint.
  ///
  /// In en, this message translates to:
  /// **'GPA, CGPA and targets'**
  String get cgpaHint;

  /// No description provided for @cgpaLabel.
  ///
  /// In en, this message translates to:
  /// **'CGPA'**
  String get cgpaLabel;

  /// No description provided for @cgpaGpa.
  ///
  /// In en, this message translates to:
  /// **'GPA {gpa}'**
  String cgpaGpa(String gpa);

  /// No description provided for @cgpaCredits.
  ///
  /// In en, this message translates to:
  /// **'{credits} credits'**
  String cgpaCredits(String credits);

  /// No description provided for @cgpaCreditsEarned.
  ///
  /// In en, this message translates to:
  /// **'Credits earned'**
  String get cgpaCreditsEarned;

  /// No description provided for @cgpaLastSemester.
  ///
  /// In en, this message translates to:
  /// **'Last semester'**
  String get cgpaLastSemester;

  /// No description provided for @cgpaScaleUgc.
  ///
  /// In en, this message translates to:
  /// **'UGC scale'**
  String get cgpaScaleUgc;

  /// No description provided for @cgpaScaleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom scale'**
  String get cgpaScaleCustom;

  /// No description provided for @cgpaNoGrades.
  ///
  /// In en, this message translates to:
  /// **'No grades yet'**
  String get cgpaNoGrades;

  /// No description provided for @cgpaCoursesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 course} other{{count} courses}}'**
  String cgpaCoursesCount(int count);

  /// No description provided for @cgpaSemesters.
  ///
  /// In en, this message translates to:
  /// **'Semesters'**
  String get cgpaSemesters;

  /// No description provided for @cgpaAddSemester.
  ///
  /// In en, this message translates to:
  /// **'Add semester'**
  String get cgpaAddSemester;

  /// No description provided for @cgpaSemesterName.
  ///
  /// In en, this message translates to:
  /// **'Semester name'**
  String get cgpaSemesterName;

  /// No description provided for @cgpaSemesterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Spring 2026'**
  String get cgpaSemesterHint;

  /// No description provided for @cgpaRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get cgpaRename;

  /// No description provided for @cgpaMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get cgpaMoveUp;

  /// No description provided for @cgpaMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get cgpaMoveDown;

  /// No description provided for @cgpaDeleteSemesterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this semester and its courses?'**
  String get cgpaDeleteSemesterTitle;

  /// No description provided for @cgpaEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Track your CGPA'**
  String get cgpaEmptyTitle;

  /// No description provided for @cgpaEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your semesters and grades. Everything stays on this phone.'**
  String get cgpaEmptyBody;

  /// No description provided for @cgpaAddCourse.
  ///
  /// In en, this message translates to:
  /// **'Add course'**
  String get cgpaAddCourse;

  /// No description provided for @cgpaEditCourse.
  ///
  /// In en, this message translates to:
  /// **'Edit course'**
  String get cgpaEditCourse;

  /// No description provided for @cgpaCourseCode.
  ///
  /// In en, this message translates to:
  /// **'Course code'**
  String get cgpaCourseCode;

  /// No description provided for @cgpaCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Course title (optional)'**
  String get cgpaCourseTitle;

  /// No description provided for @cgpaCreditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get cgpaCreditsLabel;

  /// No description provided for @cgpaCreditsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Credits must be between 0.5 and 6.'**
  String get cgpaCreditsInvalid;

  /// No description provided for @cgpaCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a course code or title.'**
  String get cgpaCodeRequired;

  /// No description provided for @cgpaGradeLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter grade'**
  String get cgpaGradeLetter;

  /// No description provided for @cgpaGradeMarks.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get cgpaGradeMarks;

  /// No description provided for @cgpaNotGraded.
  ///
  /// In en, this message translates to:
  /// **'Not graded yet'**
  String get cgpaNotGraded;

  /// No description provided for @cgpaMarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Marks out of 100'**
  String get cgpaMarksLabel;

  /// No description provided for @cgpaMarksGives.
  ///
  /// In en, this message translates to:
  /// **'Grade: {letter} ({points})'**
  String cgpaMarksGives(String letter, String points);

  /// No description provided for @cgpaMarksInvalid.
  ///
  /// In en, this message translates to:
  /// **'Marks must be 0 to 100.'**
  String get cgpaMarksInvalid;

  /// No description provided for @cgpaNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted: retaken'**
  String get cgpaNotCounted;

  /// No description provided for @cgpaFromRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add my routine\'s courses'**
  String get cgpaFromRoutine;

  /// No description provided for @cgpaFromRoutineHint.
  ///
  /// In en, this message translates to:
  /// **'Your current courses, ready to grade.'**
  String get cgpaFromRoutineHint;

  /// No description provided for @cgpaTarget.
  ///
  /// In en, this message translates to:
  /// **'Plan a target'**
  String get cgpaTarget;

  /// No description provided for @cgpaTargetCgpa.
  ///
  /// In en, this message translates to:
  /// **'Target CGPA'**
  String get cgpaTargetCgpa;

  /// No description provided for @cgpaNextCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits left to take'**
  String get cgpaNextCredits;

  /// No description provided for @cgpaTargetNeeds.
  ///
  /// In en, this message translates to:
  /// **'You need a GPA of {gpa} in those credits.'**
  String cgpaTargetNeeds(String gpa);

  /// No description provided for @cgpaTargetReached.
  ///
  /// In en, this message translates to:
  /// **'You\'re already there. Keep passing to stay above it.'**
  String get cgpaTargetReached;

  /// No description provided for @cgpaTargetOut.
  ///
  /// In en, this message translates to:
  /// **'Not reachable: it would need a GPA of {gpa}. Try more credits or a lower target.'**
  String cgpaTargetOut(String gpa);

  /// No description provided for @cgpaTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a target CGPA and the credits left.'**
  String get cgpaTargetInvalid;

  /// No description provided for @cgpaGradingScale.
  ///
  /// In en, this message translates to:
  /// **'Grading scale'**
  String get cgpaGradingScale;

  /// No description provided for @cgpaUseUgc.
  ///
  /// In en, this message translates to:
  /// **'UGC uniform scale (4.00)'**
  String get cgpaUseUgc;

  /// No description provided for @cgpaUseUgcHint.
  ///
  /// In en, this message translates to:
  /// **'Most Bangladeshi universities use it.'**
  String get cgpaUseUgcHint;

  /// No description provided for @cgpaUseCustom.
  ///
  /// In en, this message translates to:
  /// **'My university\'s own scale'**
  String get cgpaUseCustom;

  /// No description provided for @cgpaUseCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Set your own grades, points and mark ranges.'**
  String get cgpaUseCustomHint;

  /// No description provided for @cgpaGradeShort.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get cgpaGradeShort;

  /// No description provided for @cgpaPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get cgpaPoints;

  /// No description provided for @cgpaMinMarks.
  ///
  /// In en, this message translates to:
  /// **'From marks'**
  String get cgpaMinMarks;

  /// No description provided for @cgpaAddGrade.
  ///
  /// In en, this message translates to:
  /// **'Add grade'**
  String get cgpaAddGrade;

  /// No description provided for @cgpaRetakeRule.
  ///
  /// In en, this message translates to:
  /// **'Retaken courses'**
  String get cgpaRetakeRule;

  /// No description provided for @cgpaRetakeBest.
  ///
  /// In en, this message translates to:
  /// **'Best attempt counts'**
  String get cgpaRetakeBest;

  /// No description provided for @cgpaRetakeBestHint.
  ///
  /// In en, this message translates to:
  /// **'The usual rule: a better grade replaces the earlier one.'**
  String get cgpaRetakeBestHint;

  /// No description provided for @cgpaRetakeLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest attempt counts'**
  String get cgpaRetakeLatest;

  /// No description provided for @cgpaRetakeAll.
  ///
  /// In en, this message translates to:
  /// **'Every attempt counts'**
  String get cgpaRetakeAll;

  /// No description provided for @cgpaRetakeHint.
  ///
  /// In en, this message translates to:
  /// **'Attempts are matched by course code.'**
  String get cgpaRetakeHint;

  /// No description provided for @cgpaProblemEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add at least one grade.'**
  String get cgpaProblemEmpty;

  /// No description provided for @cgpaProblemLetter.
  ///
  /// In en, this message translates to:
  /// **'Every grade needs its own name.'**
  String get cgpaProblemLetter;

  /// No description provided for @cgpaProblemPoints.
  ///
  /// In en, this message translates to:
  /// **'Points must be 0 to 5.'**
  String get cgpaProblemPoints;

  /// No description provided for @cgpaProblemMarks.
  ///
  /// In en, this message translates to:
  /// **'Each grade needs its own starting mark, 0 to 100.'**
  String get cgpaProblemMarks;

  /// No description provided for @cgpaProblemZero.
  ///
  /// In en, this message translates to:
  /// **'One grade must start at 0 marks.'**
  String get cgpaProblemZero;

  /// No description provided for @cgpaProblemOrder.
  ///
  /// In en, this message translates to:
  /// **'More marks can\'t give fewer points.'**
  String get cgpaProblemOrder;

  /// No description provided for @cgpaClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear everything'**
  String get cgpaClearAll;

  /// No description provided for @cgpaClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all semesters and grades on this phone?'**
  String get cgpaClearTitle;

  /// No description provided for @cgpaSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cgpaSave;

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

  /// No description provided for @deleteAccountUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand this can\'t be undone'**
  String get deleteAccountUnderstand;

  /// No description provided for @photoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get photoAdd;

  /// No description provided for @photoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get photoChange;

  /// No description provided for @photoCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get photoCrop;

  /// No description provided for @photoTake.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoTake;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoGallery;

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get photoRemoved;

  /// No description provided for @photoNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This photo can\'t be used. Try another one.'**
  String get photoNotAllowed;

  /// No description provided for @photoCheckDown.
  ///
  /// In en, this message translates to:
  /// **'Photos can\'t be checked right now. Try again later.'**
  String get photoCheckDown;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This photo is too large.'**
  String get photoTooLarge;

  /// No description provided for @photoInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a photo we can use.'**
  String get photoInvalid;

  /// No description provided for @photoWhoSees.
  ///
  /// In en, this message translates to:
  /// **'Classmates in your class groups see your photo. Campus Voice never shows it.'**
  String get photoWhoSees;

  /// No description provided for @photoGoogleHint.
  ///
  /// In en, this message translates to:
  /// **'Your Google photo shows until you add one.'**
  String get photoGoogleHint;

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

  /// No description provided for @findClass.
  ///
  /// In en, this message translates to:
  /// **'Find your class'**
  String get findClass;

  /// No description provided for @findClassHint.
  ///
  /// In en, this message translates to:
  /// **'Department, batch, course code or teacher'**
  String get findClassHint;

  /// No description provided for @findClassIntro.
  ///
  /// In en, this message translates to:
  /// **'Search your university\'s class routines. Join a whole section, or just the courses you take.'**
  String get findClassIntro;

  /// No description provided for @findClassEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No class found'**
  String get findClassEmptyTitle;

  /// No description provided for @findClassEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try a course code (CSE 311), or department and batch. Or ask your CR for the join code.'**
  String get findClassEmptyBody;

  /// No description provided for @findClassOffline.
  ///
  /// In en, this message translates to:
  /// **'Searching needs an internet connection.'**
  String get findClassOffline;

  /// No description provided for @findClassJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get findClassJoined;

  /// No description provided for @findClassCr.
  ///
  /// In en, this message translates to:
  /// **'CR: {name}'**
  String findClassCr(String name);

  /// No description provided for @findClassMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get findClassMore;

  /// No description provided for @findClassHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have a join code?'**
  String get findClassHaveCode;

  /// No description provided for @previewPickHint.
  ///
  /// In en, this message translates to:
  /// **'Untick the courses you don\'t take. You\'ll only see the ones you keep.'**
  String get previewPickHint;

  /// No description provided for @previewNoClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes in this routine yet.'**
  String get previewNoClasses;

  /// No description provided for @joinWholeSection.
  ///
  /// In en, this message translates to:
  /// **'Join whole section'**
  String get joinWholeSection;

  /// No description provided for @addSelectedCourses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 course} other{Add {count} courses}}'**
  String addSelectedCourses(int count);

  /// No description provided for @saveMyCourses.
  ///
  /// In en, this message translates to:
  /// **'Save my courses'**
  String get saveMyCourses;

  /// No description provided for @addedToRoutine.
  ///
  /// In en, this message translates to:
  /// **'Added to your routine'**
  String get addedToRoutine;

  /// No description provided for @similarGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'This class may already exist'**
  String get similarGroupsTitle;

  /// No description provided for @similarGroupsBody.
  ///
  /// In en, this message translates to:
  /// **'Join it instead, so your class keeps one routine.'**
  String get similarGroupsBody;

  /// No description provided for @joinInstead.
  ///
  /// In en, this message translates to:
  /// **'Join instead'**
  String get joinInstead;

  /// No description provided for @findableTitle.
  ///
  /// In en, this message translates to:
  /// **'Findable at {university}'**
  String findableTitle(String university);

  /// No description provided for @findableBody.
  ///
  /// In en, this message translates to:
  /// **'Students of your university can find this class by search. Off: only people with the join code can join.'**
  String get findableBody;

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

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get shareInvite;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied. Paste it in your class group.'**
  String get inviteCopied;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join {group} on {app}: {link}\nOr open the app, tap \"Join with a code\" and enter {code}'**
  String inviteMessage(String group, String app, String link, String code);

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
  /// **'Change day, time or room'**
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
  /// **'Name, short name or city'**
  String get searchUniversity;

  /// No description provided for @universityPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, a short name like DIU, or city.'**
  String get universityPickerHint;

  /// No description provided for @currentUniversity.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentUniversity;

  /// No description provided for @allUniversities.
  ///
  /// In en, this message translates to:
  /// **'All universities'**
  String get allUniversities;

  /// No description provided for @universityMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String universityMatches(int count);

  /// No description provided for @noUniversityFound.
  ///
  /// In en, this message translates to:
  /// **'No university found'**
  String get noUniversityFound;

  /// No description provided for @noUniversityFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try a short name like DIU or the email domain.'**
  String get noUniversityFoundHint;

  /// No description provided for @askToAddUniversity.
  ///
  /// In en, this message translates to:
  /// **'Ask us to add it'**
  String get askToAddUniversity;

  /// No description provided for @addUniversitySubject.
  ///
  /// In en, this message translates to:
  /// **'Please add my university'**
  String get addUniversitySubject;

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

  /// No description provided for @movedToDay.
  ///
  /// In en, this message translates to:
  /// **'Moved to {day}'**
  String movedToDay(String day);

  /// No description provided for @movedFromDay.
  ///
  /// In en, this message translates to:
  /// **'Moved from {day}'**
  String movedFromDay(String day);

  /// No description provided for @movedDayNotice.
  ///
  /// In en, this message translates to:
  /// **'This week only: from {from} to {to}. The weekly routine stays the same.'**
  String movedDayNotice(String from, String to);

  /// No description provided for @dayTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to move it to another day'**
  String get dayTapToChange;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dayTomorrow;

  /// No description provided for @testsAndDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Tests & deadlines'**
  String get testsAndDeadlines;

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @addTest.
  ///
  /// In en, this message translates to:
  /// **'Add test or deadline'**
  String get addTest;

  /// No description provided for @editTest.
  ///
  /// In en, this message translates to:
  /// **'Edit test or deadline'**
  String get editTest;

  /// No description provided for @noTestsYet.
  ///
  /// In en, this message translates to:
  /// **'No tests or deadlines yet. Anyone in the group can add one.'**
  String get noTestsYet;

  /// No description provided for @testKindLabel.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get testKindLabel;

  /// No description provided for @kindClassTest.
  ///
  /// In en, this message translates to:
  /// **'Class test'**
  String get kindClassTest;

  /// No description provided for @kindQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get kindQuiz;

  /// No description provided for @kindAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get kindAssignment;

  /// No description provided for @kindLabReport.
  ///
  /// In en, this message translates to:
  /// **'Lab report'**
  String get kindLabReport;

  /// No description provided for @kindPresentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get kindPresentation;

  /// No description provided for @kindMidterm.
  ///
  /// In en, this message translates to:
  /// **'Mid-term'**
  String get kindMidterm;

  /// No description provided for @kindFinal.
  ///
  /// In en, this message translates to:
  /// **'Final exam'**
  String get kindFinal;

  /// No description provided for @kindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kindOther;

  /// No description provided for @testTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get testTimeLabel;

  /// No description provided for @testNoTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get testNoTime;

  /// No description provided for @testAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get testAddTime;

  /// No description provided for @testAddEnd.
  ///
  /// In en, this message translates to:
  /// **'Add an end time'**
  String get testAddEnd;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueLabel;

  /// No description provided for @dueAt.
  ///
  /// In en, this message translates to:
  /// **'Due {time}'**
  String dueAt(String time);

  /// No description provided for @topicsLabel.
  ///
  /// In en, this message translates to:
  /// **'Topics or details (optional)'**
  String get topicsLabel;

  /// No description provided for @topicsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chapters 1–3, bring a calculator'**
  String get topicsHint;

  /// No description provided for @testSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Classmates get a notification.'**
  String get testSaved;

  /// No description provided for @testDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get testDeleted;

  /// No description provided for @deleteTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this {kind}?'**
  String deleteTestTitle(String kind);

  /// No description provided for @deleteTestBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed for everyone in the group.'**
  String get deleteTestBody;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String addedBy(String name);

  /// No description provided for @testOnlyOwnerHint.
  ///
  /// In en, this message translates to:
  /// **'Only who added it or a CR can change it.'**
  String get testOnlyOwnerHint;

  /// No description provided for @reminderTestTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {kind} · {course}'**
  String reminderTestTomorrow(String kind, String course);

  /// No description provided for @reminderTestSoon.
  ///
  /// In en, this message translates to:
  /// **'{kind} soon · {course}'**
  String reminderTestSoon(String kind, String course);

  /// No description provided for @reminderTestToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {kind} · {course}'**
  String reminderTestToday(String kind, String course);

  /// No description provided for @errorAssessmentDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date from today, within 6 months.'**
  String get errorAssessmentDate;

  /// No description provided for @errorAssessmentLimit.
  ///
  /// In en, this message translates to:
  /// **'This group already has the most upcoming tests and deadlines allowed.'**
  String get errorAssessmentLimit;

  /// No description provided for @errorAssessmentGone.
  ///
  /// In en, this message translates to:
  /// **'This was already deleted.'**
  String get errorAssessmentGone;

  /// No description provided for @errorNotAssessmentOwner.
  ///
  /// In en, this message translates to:
  /// **'Only who added it or a CR can change it.'**
  String get errorNotAssessmentOwner;

  /// No description provided for @errorMoveDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a day from today, within 6 months.'**
  String get errorMoveDate;

  /// No description provided for @navCampus.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get navCampus;

  /// No description provided for @voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Campus Voice'**
  String get voiceTitle;

  /// No description provided for @voiceSortTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get voiceSortTrending;

  /// No description provided for @voiceSortNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get voiceSortNew;

  /// No description provided for @voiceSortSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get voiceSortSolved;

  /// No description provided for @voiceAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get voiceAllCategories;

  /// No description provided for @voiceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search issues'**
  String get voiceSearchHint;

  /// No description provided for @voiceRaiseIssue.
  ///
  /// In en, this message translates to:
  /// **'Raise issue'**
  String get voiceRaiseIssue;

  /// No description provided for @voiceMyIssues.
  ///
  /// In en, this message translates to:
  /// **'My issues'**
  String get voiceMyIssues;

  /// No description provided for @voiceSafetyReports.
  ///
  /// In en, this message translates to:
  /// **'Safety reports'**
  String get voiceSafetyReports;

  /// No description provided for @voiceEmptyFeed.
  ///
  /// In en, this message translates to:
  /// **'No issues here yet'**
  String get voiceEmptyFeed;

  /// No description provided for @voiceEmptyFeedHint.
  ///
  /// In en, this message translates to:
  /// **'Something wrong on campus? Raise it. You stay anonymous.'**
  String get voiceEmptyFeedHint;

  /// No description provided for @voiceEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No issues match your search'**
  String get voiceEmptySearch;

  /// No description provided for @voiceEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t raised an issue yet'**
  String get voiceEmptyMine;

  /// No description provided for @voiceEmptyMineHint.
  ///
  /// In en, this message translates to:
  /// **'Issues you raise show here, including ones under review.'**
  String get voiceEmptyMineHint;

  /// No description provided for @voiceCatAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get voiceCatAcademic;

  /// No description provided for @voiceCatHostel.
  ///
  /// In en, this message translates to:
  /// **'Hostel'**
  String get voiceCatHostel;

  /// No description provided for @voiceCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get voiceCatTransport;

  /// No description provided for @voiceCatFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get voiceCatFacilities;

  /// No description provided for @voiceCatSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get voiceCatSafety;

  /// No description provided for @voiceCatAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get voiceCatAdministration;

  /// No description provided for @voiceCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get voiceCatFood;

  /// No description provided for @voiceCatIt.
  ///
  /// In en, this message translates to:
  /// **'IT / Wi-Fi'**
  String get voiceCatIt;

  /// No description provided for @voiceCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get voiceCatOther;

  /// No description provided for @voiceStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get voiceStatusOpen;

  /// No description provided for @voiceStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get voiceStatusAcknowledged;

  /// No description provided for @voiceStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get voiceStatusInProgress;

  /// No description provided for @voiceStatusSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get voiceStatusSolved;

  /// No description provided for @voiceStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get voiceStatusRejected;

  /// No description provided for @voiceUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get voiceUnderReview;

  /// No description provided for @voiceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get voiceRemoved;

  /// No description provided for @voiceHiddenBadge.
  ///
  /// In en, this message translates to:
  /// **'Hidden for review'**
  String get voiceHiddenBadge;

  /// No description provided for @voicePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get voicePrivate;

  /// No description provided for @voiceAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get voiceAnonymous;

  /// No description provided for @voiceYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get voiceYou;

  /// No description provided for @voiceHandle.
  ///
  /// In en, this message translates to:
  /// **'Student {handle}'**
  String voiceHandle(String handle);

  /// No description provided for @voiceAuthorTag.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get voiceAuthorTag;

  /// No description provided for @voiceDeletedAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleted account'**
  String get voiceDeletedAccount;

  /// No description provided for @voiceOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get voiceOfficial;

  /// No description provided for @voiceMeToo.
  ///
  /// In en, this message translates to:
  /// **'Me too'**
  String get voiceMeToo;

  /// No description provided for @voiceMeTooSemantics.
  ///
  /// In en, this message translates to:
  /// **'Me too, {count} students'**
  String voiceMeTooSemantics(int count);

  /// No description provided for @voiceFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get voiceFollow;

  /// No description provided for @voiceFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get voiceFollowing;

  /// No description provided for @voiceComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get voiceComments;

  /// No description provided for @voiceStatusHistory.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get voiceStatusHistory;

  /// No description provided for @voiceRaised.
  ///
  /// In en, this message translates to:
  /// **'Raised'**
  String get voiceRaised;

  /// No description provided for @voiceStepBy.
  ///
  /// In en, this message translates to:
  /// **'{who} · {when}'**
  String voiceStepBy(String who, String when);

  /// No description provided for @voiceActorAuthor.
  ///
  /// In en, this message translates to:
  /// **'The author'**
  String get voiceActorAuthor;

  /// No description provided for @voiceActorModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get voiceActorModerator;

  /// No description provided for @voiceActorSystem.
  ///
  /// In en, this message translates to:
  /// **'VarsityKotha'**
  String get voiceActorSystem;

  /// No description provided for @voiceHeldNotice.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this while it\'s checked. It usually takes less than a day.'**
  String get voiceHeldNotice;

  /// No description provided for @voiceHeldPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'It may contain a phone number, email, link or ID number.'**
  String get voiceHeldPersonalInfo;

  /// No description provided for @voiceHeldLanguage.
  ///
  /// In en, this message translates to:
  /// **'It may contain words that aren\'t allowed.'**
  String get voiceHeldLanguage;

  /// No description provided for @voiceHeldPhoto.
  ///
  /// In en, this message translates to:
  /// **'A moderator checks a photo in this post first.'**
  String get voiceHeldPhoto;

  /// No description provided for @voiceHeldUnverified.
  ///
  /// In en, this message translates to:
  /// **'Posts from accounts without a verified university email are checked first.'**
  String get voiceHeldUnverified;

  /// No description provided for @voiceRemovedNotice.
  ///
  /// In en, this message translates to:
  /// **'Removed by moderators: {reason}'**
  String voiceRemovedNotice(String reason);

  /// No description provided for @voiceRemovedByYou.
  ///
  /// In en, this message translates to:
  /// **'You deleted this issue.'**
  String get voiceRemovedByYou;

  /// No description provided for @voiceHiddenNotice.
  ///
  /// In en, this message translates to:
  /// **'Hidden while moderators look at reports.'**
  String get voiceHiddenNotice;

  /// No description provided for @voicePrivateNotice.
  ///
  /// In en, this message translates to:
  /// **'Private: only you, moderators and your university\'s officials can see this.'**
  String get voicePrivateNotice;

  /// No description provided for @voiceCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get voiceCommentHint;

  /// No description provided for @voiceCommentAs.
  ///
  /// In en, this message translates to:
  /// **'Commenting as {who}'**
  String voiceCommentAs(String who);

  /// No description provided for @voiceCommentAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Anonymously'**
  String get voiceCommentAnonymously;

  /// No description provided for @voiceCommentWithName.
  ///
  /// In en, this message translates to:
  /// **'With my name'**
  String get voiceCommentWithName;

  /// No description provided for @voiceNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get voiceNoComments;

  /// No description provided for @voiceCommentRemoved.
  ///
  /// In en, this message translates to:
  /// **'This comment was removed.'**
  String get voiceCommentRemoved;

  /// No description provided for @voiceCommentUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this comment while it\'s checked.'**
  String get voiceCommentUnderReview;

  /// No description provided for @voiceLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get voiceLoadMore;

  /// No description provided for @voiceSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get voiceSend;

  /// No description provided for @voiceReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get voiceReport;

  /// No description provided for @voiceReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get voiceReopen;

  /// No description provided for @voiceReopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen this issue?'**
  String get voiceReopenTitle;

  /// No description provided for @voiceReopenHint.
  ///
  /// In en, this message translates to:
  /// **'Tell officials what\'s still wrong'**
  String get voiceReopenHint;

  /// No description provided for @voiceDeleteIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this issue?'**
  String get voiceDeleteIssueTitle;

  /// No description provided for @voiceDeleteIssueBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears for everyone. This can\'t be undone.'**
  String get voiceDeleteIssueBody;

  /// No description provided for @voiceDeleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get voiceDeleteCommentTitle;

  /// No description provided for @voiceEditIssue.
  ///
  /// In en, this message translates to:
  /// **'Edit issue'**
  String get voiceEditIssue;

  /// No description provided for @voiceEditWindow.
  ///
  /// In en, this message translates to:
  /// **'You can edit for 60 minutes after posting.'**
  String get voiceEditWindow;

  /// No description provided for @voiceReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get voiceReportTitle;

  /// No description provided for @voiceReportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get voiceReportSpam;

  /// No description provided for @voiceReportAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abusive or hateful'**
  String get voiceReportAbuse;

  /// No description provided for @voiceReportPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Shares someone\'s personal information'**
  String get voiceReportPersonalInfo;

  /// No description provided for @voiceReportFalseInfo.
  ///
  /// In en, this message translates to:
  /// **'False information'**
  String get voiceReportFalseInfo;

  /// No description provided for @voiceReportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get voiceReportInappropriate;

  /// No description provided for @voiceReportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get voiceReportOther;

  /// No description provided for @voiceReportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get voiceReportDetails;

  /// No description provided for @voiceReportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Moderators will look at it.'**
  String get voiceReportSent;

  /// No description provided for @voiceReportAnon.
  ///
  /// In en, this message translates to:
  /// **'Reports are anonymous.'**
  String get voiceReportAnon;

  /// No description provided for @voiceChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get voiceChangeStatus;

  /// No description provided for @voiceStatusNote.
  ///
  /// In en, this message translates to:
  /// **'Note for students'**
  String get voiceStatusNote;

  /// No description provided for @voiceStatusNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s being done, or why'**
  String get voiceStatusNoteHint;

  /// No description provided for @voiceNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Say why it\'s rejected.'**
  String get voiceNoteRequired;

  /// No description provided for @voiceOfficialReply.
  ///
  /// In en, this message translates to:
  /// **'Official reply'**
  String get voiceOfficialReply;

  /// No description provided for @voiceOfficialReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a public reply. Your title and name are shown.'**
  String get voiceOfficialReplyHint;

  /// No description provided for @voiceStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get voiceStatusUpdated;

  /// No description provided for @voiceReplyPosted.
  ///
  /// In en, this message translates to:
  /// **'Reply posted'**
  String get voiceReplyPosted;

  /// No description provided for @voiceOfficialBadge.
  ///
  /// In en, this message translates to:
  /// **'University official'**
  String get voiceOfficialBadge;

  /// No description provided for @voiceNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Raise an issue'**
  String get voiceNewTitle;

  /// No description provided for @voiceStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3'**
  String voiceStepOf(int step);

  /// No description provided for @voiceStepCategory.
  ///
  /// In en, this message translates to:
  /// **'What is it about?'**
  String get voiceStepCategory;

  /// No description provided for @voiceSafetyNote.
  ///
  /// In en, this message translates to:
  /// **'Safety reports are private: only moderators and your university\'s officials see them.'**
  String get voiceSafetyNote;

  /// No description provided for @voiceStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s wrong'**
  String get voiceStepDetails;

  /// No description provided for @voiceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get voiceTitleLabel;

  /// No description provided for @voiceTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. No water in Hall 2 since Sunday'**
  String get voiceTitleHint;

  /// No description provided for @voiceBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get voiceBodyLabel;

  /// No description provided for @voiceBodyHint.
  ///
  /// In en, this message translates to:
  /// **'What happens, where and since when. Don\'t include names, phone numbers or roll numbers.'**
  String get voiceBodyHint;

  /// No description provided for @voicePlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Place (optional)'**
  String get voicePlaceLabel;

  /// No description provided for @voicePlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Library, 3rd floor'**
  String get voicePlaceHint;

  /// No description provided for @voicePhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get voicePhotosLabel;

  /// No description provided for @voiceAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get voiceAddPhoto;

  /// No description provided for @voicePhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 4. Location and phone details are removed.'**
  String get voicePhotosHint;

  /// No description provided for @voicePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}'**
  String voicePhoto(int n);

  /// No description provided for @voiceRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get voiceRemovePhoto;

  /// No description provided for @voiceAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Write at least {n} characters.'**
  String voiceAtLeast(int n);

  /// No description provided for @voiceStepReview.
  ///
  /// In en, this message translates to:
  /// **'Before you post'**
  String get voiceStepReview;

  /// No description provided for @voiceSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar issues'**
  String get voiceSimilarTitle;

  /// No description provided for @voiceSimilarHint.
  ///
  /// In en, this message translates to:
  /// **'If one of these is the same, tap Me too there instead of posting again.'**
  String get voiceSimilarHint;

  /// No description provided for @voiceNoSimilar.
  ///
  /// In en, this message translates to:
  /// **'No similar issues found.'**
  String get voiceNoSimilar;

  /// No description provided for @voicePostAnon.
  ///
  /// In en, this message translates to:
  /// **'Post anonymously'**
  String get voicePostAnon;

  /// No description provided for @voicePostAnonHint.
  ///
  /// In en, this message translates to:
  /// **'Your name, email and class are never shown.'**
  String get voicePostAnonHint;

  /// No description provided for @voicePostNamedHint.
  ///
  /// In en, this message translates to:
  /// **'Students will see your name on this post.'**
  String get voicePostNamedHint;

  /// No description provided for @voiceHowAnonymity.
  ///
  /// In en, this message translates to:
  /// **'How anonymity works'**
  String get voiceHowAnonymity;

  /// No description provided for @voicePost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get voicePost;

  /// No description provided for @voiceNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get voiceNext;

  /// No description provided for @voiceBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get voiceBack;

  /// No description provided for @voicePosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get voicePosted;

  /// No description provided for @voicePostedHeld.
  ///
  /// In en, this message translates to:
  /// **'Posted. Others will see it after a quick check.'**
  String get voicePostedHeld;

  /// No description provided for @voiceUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get voiceUploading;

  /// No description provided for @voiceDraftKept.
  ///
  /// In en, this message translates to:
  /// **'Your draft is kept on this phone.'**
  String get voiceDraftKept;

  /// No description provided for @voiceOfflineAction.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Try again when you\'re connected.'**
  String get voiceOfflineAction;

  /// No description provided for @voiceAnonTitle.
  ///
  /// In en, this message translates to:
  /// **'How anonymity works'**
  String get voiceAnonTitle;

  /// No description provided for @voiceAnonIntro.
  ///
  /// In en, this message translates to:
  /// **'Campus Voice is built so you can speak up safely.'**
  String get voiceAnonIntro;

  /// No description provided for @voiceAnon1.
  ///
  /// In en, this message translates to:
  /// **'Your name, email and class are never shown on anonymous posts.'**
  String get voiceAnon1;

  /// No description provided for @voiceAnon2.
  ///
  /// In en, this message translates to:
  /// **'Who wrote what is stored separately. No screen, staff member or university official can see it, in the app or in our admin panel.'**
  String get voiceAnon2;

  /// No description provided for @voiceAnon3.
  ///
  /// In en, this message translates to:
  /// **'Your handle (like “Student 7KQF”) is different on every issue.'**
  String get voiceAnon3;

  /// No description provided for @voiceAnon4.
  ///
  /// In en, this message translates to:
  /// **'Photos are cleaned: location and phone details are removed.'**
  String get voiceAnon4;

  /// No description provided for @voiceAnon5.
  ///
  /// In en, this message translates to:
  /// **'Times are shown roughly, not to the minute.'**
  String get voiceAnon5;

  /// No description provided for @voiceAnon6.
  ///
  /// In en, this message translates to:
  /// **'Breaking the rules (threats, naming people, spam) can get your posting blocked, without anyone seeing who you are.'**
  String get voiceAnon6;

  /// No description provided for @voiceAnon7.
  ///
  /// In en, this message translates to:
  /// **'What you write can still give you away. Don\'t include your name, roll number or details only you would know. Anyone can screenshot a public post.'**
  String get voiceAnon7;

  /// No description provided for @voiceAnon8.
  ///
  /// In en, this message translates to:
  /// **'Safety reports are private: only moderators and your university\'s officials see them.'**
  String get voiceAnon8;

  /// No description provided for @errorFeatureDisabled.
  ///
  /// In en, this message translates to:
  /// **'Campus Voice isn\'t open yet.'**
  String get errorFeatureDisabled;

  /// No description provided for @errorVoiceBanned.
  ///
  /// In en, this message translates to:
  /// **'You can\'t post, comment or vote right now because of a rules break.'**
  String get errorVoiceBanned;

  /// No description provided for @errorVoiceBannedUntil.
  ///
  /// In en, this message translates to:
  /// **'You can\'t post, comment or vote until {date} because of a rules break.'**
  String errorVoiceBannedUntil(String date);

  /// No description provided for @errorIssueNotFound.
  ///
  /// In en, this message translates to:
  /// **'This issue isn\'t available.'**
  String get errorIssueNotFound;

  /// No description provided for @errorCommentNotFound.
  ///
  /// In en, this message translates to:
  /// **'This comment isn\'t available.'**
  String get errorCommentNotFound;

  /// No description provided for @errorUploadNotFound.
  ///
  /// In en, this message translates to:
  /// **'A photo didn\'t finish uploading. Remove it and add it again.'**
  String get errorUploadNotFound;

  /// No description provided for @errorImageInvalid.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a photo we can use.'**
  String get errorImageInvalid;

  /// No description provided for @errorImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large.'**
  String get errorImageTooLarge;

  /// No description provided for @errorPhotoNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This photo can\'t be posted. Choose another photo.'**
  String get errorPhotoNotAllowed;

  /// No description provided for @voicePhotoRefused.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be posted'**
  String get voicePhotoRefused;

  /// No description provided for @errorEditWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Issues can only be edited in the first 60 minutes.'**
  String get errorEditWindowClosed;

  /// No description provided for @errorReopenNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only solved issues can be reopened, within 30 days.'**
  String get errorReopenNotAllowed;

  /// No description provided for @errorIssueClosed.
  ///
  /// In en, this message translates to:
  /// **'This issue was removed, so it can\'t get new comments.'**
  String get errorIssueClosed;

  /// No description provided for @errorCannotVoteOwn.
  ///
  /// In en, this message translates to:
  /// **'You raised this issue, so it already counts you.'**
  String get errorCannotVoteOwn;

  /// No description provided for @errorAlreadyReported.
  ///
  /// In en, this message translates to:
  /// **'You already reported this.'**
  String get errorAlreadyReported;

  /// No description provided for @errorStatusChangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That status change isn\'t possible.'**
  String get errorStatusChangeInvalid;

  /// No description provided for @errorNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a note saying why.'**
  String get errorNoteRequired;

  /// No description provided for @voiceFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get voiceFromGallery;

  /// No description provided for @voiceTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get voiceTakePhoto;

  /// No description provided for @voiceHeldModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderators hid this while they look at it.'**
  String get voiceHeldModerator;

  /// No description provided for @campusTitle.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get campusTitle;

  /// No description provided for @campusPrompt.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening on campus?'**
  String get campusPrompt;

  /// No description provided for @campusTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get campusTabForYou;

  /// No description provided for @campusTabLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get campusTabLatest;

  /// No description provided for @campusTabAsk.
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get campusTabAsk;

  /// No description provided for @campusTabIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get campusTabIssues;

  /// No description provided for @campusIssuesOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get campusIssuesOpen;

  /// No description provided for @campusKindPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get campusKindPost;

  /// No description provided for @campusKindQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get campusKindQuestion;

  /// No description provided for @campusKindPoll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get campusKindPoll;

  /// No description provided for @campusKindIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get campusKindIssue;

  /// No description provided for @campusBadgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get campusBadgeQuestion;

  /// No description provided for @campusBadgePoll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get campusBadgePoll;

  /// No description provided for @campusQuickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get campusQuickPhoto;

  /// No description provided for @voiceCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get voiceCatGeneral;

  /// No description provided for @voiceCatEvent.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get voiceCatEvent;

  /// No description provided for @voiceCatLostFound.
  ///
  /// In en, this message translates to:
  /// **'Lost & found'**
  String get voiceCatLostFound;

  /// No description provided for @voiceCatBuySell.
  ///
  /// In en, this message translates to:
  /// **'Buy & sell'**
  String get voiceCatBuySell;

  /// No description provided for @voiceCatFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get voiceCatFun;

  /// No description provided for @reactLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get reactLike;

  /// No description provided for @reactHaha.
  ///
  /// In en, this message translates to:
  /// **'Haha'**
  String get reactHaha;

  /// No description provided for @reactWow.
  ///
  /// In en, this message translates to:
  /// **'Wow'**
  String get reactWow;

  /// No description provided for @reactSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get reactSad;

  /// No description provided for @reactClap.
  ///
  /// In en, this message translates to:
  /// **'Clap'**
  String get reactClap;

  /// No description provided for @campusComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get campusComment;

  /// No description provided for @campusAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get campusAnswer;

  /// No description provided for @campusShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get campusShare;

  /// No description provided for @campusSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get campusSeeMore;

  /// No description provided for @campusCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String campusCommentCount(int count);

  /// No description provided for @campusAnswerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 answer} other{{count} answers}}'**
  String campusAnswerCount(int count);

  /// No description provided for @campusReactSemantics.
  ///
  /// In en, this message translates to:
  /// **'React. {count} reactions'**
  String campusReactSemantics(int count);

  /// No description provided for @campusLikeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Like. {count} likes'**
  String campusLikeSemantics(int count);

  /// No description provided for @campusPollVotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vote} other{{count} votes}}'**
  String campusPollVotes(int count);

  /// No description provided for @campusPollDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String campusPollDaysLeft(int count);

  /// No description provided for @campusPollHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour left} other{{count} hours left}}'**
  String campusPollHoursLeft(int count);

  /// No description provided for @campusPollEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ends soon'**
  String get campusPollEndingSoon;

  /// No description provided for @campusPollFinal.
  ///
  /// In en, this message translates to:
  /// **'Final results'**
  String get campusPollFinal;

  /// No description provided for @campusPollVoteToSee.
  ///
  /// In en, this message translates to:
  /// **'Vote to see the results'**
  String get campusPollVoteToSee;

  /// No description provided for @campusReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get campusReply;

  /// No description provided for @campusReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String campusReplyingTo(String name);

  /// No description provided for @campusViewReplies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{View 1 reply} other{View {count} replies}}'**
  String campusViewReplies(int count);

  /// No description provided for @campusHideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get campusHideReplies;

  /// No description provided for @campusReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get campusReplyHint;

  /// No description provided for @campusAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Write an answer…'**
  String get campusAnswerHint;

  /// No description provided for @campusNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get campusNewPost;

  /// No description provided for @campusCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get campusCreateTitle;

  /// No description provided for @campusPostAction.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get campusPostAction;

  /// No description provided for @campusPostHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get campusPostHint;

  /// No description provided for @campusQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the campus anything…'**
  String get campusQuestionHint;

  /// No description provided for @campusPollHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question…'**
  String get campusPollHint;

  /// No description provided for @campusPollOption.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String campusPollOption(int n);

  /// No description provided for @campusPollAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get campusPollAddOption;

  /// No description provided for @campusPollLength.
  ///
  /// In en, this message translates to:
  /// **'Poll length'**
  String get campusPollLength;

  /// No description provided for @campusPollDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String campusPollDays(int count);

  /// No description provided for @campusPostingAs.
  ///
  /// In en, this message translates to:
  /// **'Posting as'**
  String get campusPostingAs;

  /// No description provided for @campusTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get campusTopic;

  /// No description provided for @campusIssueNote.
  ///
  /// In en, this message translates to:
  /// **'Issues go to your university\'s officials, who can reply and update the status.'**
  String get campusIssueNote;

  /// No description provided for @campusShareText.
  ///
  /// In en, this message translates to:
  /// **'{text}\n\nSee it on VarsityKotha: {link}'**
  String campusShareText(String text, String link);

  /// No description provided for @campusMyPosts.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get campusMyPosts;

  /// No description provided for @campusEmptyFeed.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get campusEmptyFeed;

  /// No description provided for @campusEmptyFeedHint.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation: share something or ask a question.'**
  String get campusEmptyFeedHint;

  /// No description provided for @campusEmptyAsk.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get campusEmptyAsk;

  /// No description provided for @campusEmptyAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything: seniors and classmates here can answer.'**
  String get campusEmptyAskHint;

  /// No description provided for @campusEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted yet'**
  String get campusEmptyMine;

  /// No description provided for @campusEmptyMineHint.
  ///
  /// In en, this message translates to:
  /// **'Your posts, questions, polls and issues show here.'**
  String get campusEmptyMineHint;

  /// No description provided for @campusEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search'**
  String get campusEmptySearch;

  /// No description provided for @campusSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Campus'**
  String get campusSearchHint;

  /// No description provided for @campusDeletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get campusDeletePostTitle;

  /// No description provided for @campusEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get campusEditPost;

  /// No description provided for @campusTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get campusTextLabel;

  /// No description provided for @campusPhotoOrText.
  ///
  /// In en, this message translates to:
  /// **'Write something or add a photo.'**
  String get campusPhotoOrText;

  /// No description provided for @campusPollNeedsOptions.
  ///
  /// In en, this message translates to:
  /// **'Add at least two different options.'**
  String get campusPollNeedsOptions;

  /// No description provided for @campusQuestionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Write the question in a few more words.'**
  String get campusQuestionTooShort;

  /// No description provided for @errorPollClosed.
  ///
  /// In en, this message translates to:
  /// **'This poll has ended.'**
  String get errorPollClosed;

  /// No description provided for @errorAlreadyVoted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already voted in this poll.'**
  String get errorAlreadyVoted;

  /// No description provided for @errorNotAnIssue.
  ///
  /// In en, this message translates to:
  /// **'This can only be done on issues.'**
  String get errorNotAnIssue;

  /// No description provided for @editAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Edit announcement'**
  String get editAnnouncement;

  /// No description provided for @editedLabel.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editedLabel;

  /// No description provided for @announcementSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Classmates see the new text.'**
  String get announcementSaved;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @openLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this link.'**
  String get openLinkFailed;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @courseLinks.
  ///
  /// In en, this message translates to:
  /// **'Course links'**
  String get courseLinks;

  /// No description provided for @courseLinksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add chat group, Classroom code…'**
  String get courseLinksAdd;

  /// No description provided for @courseLinksEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit course links'**
  String get courseLinksEdit;

  /// No description provided for @courseLinksOptional.
  ///
  /// In en, this message translates to:
  /// **'All optional. Everyone in the group sees them.'**
  String get courseLinksOptional;

  /// No description provided for @courseLinksSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Classmates see them in the class details.'**
  String get courseLinksSaved;

  /// No description provided for @courseChat.
  ///
  /// In en, this message translates to:
  /// **'Class chat group'**
  String get courseChat;

  /// No description provided for @courseChatHint.
  ///
  /// In en, this message translates to:
  /// **'chat.whatsapp.com/… or m.me/j/…'**
  String get courseChatHint;

  /// No description provided for @courseClassroom.
  ///
  /// In en, this message translates to:
  /// **'Google Classroom'**
  String get courseClassroom;

  /// No description provided for @courseClassroomCode.
  ///
  /// In en, this message translates to:
  /// **'Classroom code'**
  String get courseClassroomCode;

  /// No description provided for @courseClassroomCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ab3x9kq'**
  String get courseClassroomCodeHint;

  /// No description provided for @courseOpenClassroom.
  ///
  /// In en, this message translates to:
  /// **'Open Classroom'**
  String get courseOpenClassroom;

  /// No description provided for @courseMaterials.
  ///
  /// In en, this message translates to:
  /// **'Course materials'**
  String get courseMaterials;

  /// No description provided for @courseMaterialsHint.
  ///
  /// In en, this message translates to:
  /// **'drive.google.com/…'**
  String get courseMaterialsHint;

  /// No description provided for @courseTeacherEmail.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s email'**
  String get courseTeacherEmail;

  /// No description provided for @courseNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get courseNotes;

  /// No description provided for @courseNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Office hours, how to submit assignments…'**
  String get courseNotesHint;

  /// No description provided for @courseLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a web link, like chat.whatsapp.com/…'**
  String get courseLinkInvalid;

  /// No description provided for @courseEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get courseEmailInvalid;

  /// No description provided for @courseCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers only (3–20).'**
  String get courseCodeInvalid;

  /// No description provided for @courseClassroomChip.
  ///
  /// In en, this message translates to:
  /// **'Classroom: {code}'**
  String courseClassroomChip(String code);

  /// No description provided for @courseMaterialsShort.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get courseMaterialsShort;

  /// No description provided for @courseCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get courseCopied;

  /// No description provided for @bloodTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood donation'**
  String get bloodTitle;

  /// No description provided for @bloodHint.
  ///
  /// In en, this message translates to:
  /// **'Find donors fast, or help someone in need.'**
  String get bloodHint;

  /// No description provided for @bloodBecomeDonor.
  ///
  /// In en, this message translates to:
  /// **'Become a donor'**
  String get bloodBecomeDonor;

  /// No description provided for @bloodBecomeDonorHint.
  ///
  /// In en, this message translates to:
  /// **'When someone at your university needs your blood group, you\'ll get a notification.'**
  String get bloodBecomeDonorHint;

  /// No description provided for @bloodYourGroup.
  ///
  /// In en, this message translates to:
  /// **'Your blood group'**
  String get bloodYourGroup;

  /// No description provided for @bloodAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available to donate'**
  String get bloodAvailable;

  /// No description provided for @bloodAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Get notified about requests for your group.'**
  String get bloodAvailableHint;

  /// No description provided for @bloodCanDonateNow.
  ///
  /// In en, this message translates to:
  /// **'You can donate now'**
  String get bloodCanDonateNow;

  /// No description provided for @bloodCanDonateFrom.
  ///
  /// In en, this message translates to:
  /// **'You can donate again from {date}'**
  String bloodCanDonateFrom(String date);

  /// No description provided for @bloodDonationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No donations yet} =1{Donated once} other{Donated {count} times}}'**
  String bloodDonationsCount(int count);

  /// No description provided for @bloodIDonated.
  ///
  /// In en, this message translates to:
  /// **'I donated today'**
  String get bloodIDonated;

  /// No description provided for @bloodDonatedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! You\'ve helped save a life.'**
  String get bloodDonatedThanks;

  /// No description provided for @bloodEditDonor.
  ///
  /// In en, this message translates to:
  /// **'Edit donor profile'**
  String get bloodEditDonor;

  /// No description provided for @bloodLeaveDonors.
  ///
  /// In en, this message translates to:
  /// **'Stop being a donor'**
  String get bloodLeaveDonors;

  /// No description provided for @bloodLeaveDonorsConfirm.
  ///
  /// In en, this message translates to:
  /// **'You won\'t get blood requests any more. You can join again anytime.'**
  String get bloodLeaveDonorsConfirm;

  /// No description provided for @bloodLastDonated.
  ///
  /// In en, this message translates to:
  /// **'Last donated'**
  String get bloodLastDonated;

  /// No description provided for @bloodNeverDonated.
  ///
  /// In en, this message translates to:
  /// **'Never, or don\'t remember'**
  String get bloodNeverDonated;

  /// No description provided for @bloodPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get bloodPhone;

  /// No description provided for @bloodPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Shared only with someone you offer to donate to.'**
  String get bloodPhoneHint;

  /// No description provided for @bloodPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number like 01712345678.'**
  String get bloodPhoneInvalid;

  /// No description provided for @bloodPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your blood group stays private: no one can browse donors.'**
  String get bloodPrivacyNote;

  /// No description provided for @bloodSaveDonor.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bloodSaveDonor;

  /// No description provided for @bloodRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get bloodRequests;

  /// No description provided for @bloodMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get bloodMyRequests;

  /// No description provided for @bloodMyGroupOnly.
  ///
  /// In en, this message translates to:
  /// **'My group'**
  String get bloodMyGroupOnly;

  /// No description provided for @bloodNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No one needs blood right now'**
  String get bloodNoRequests;

  /// No description provided for @bloodNoRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'When someone at your university does, it shows here.'**
  String get bloodNoRequestsHint;

  /// No description provided for @bloodNoMyRequests.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t asked for blood'**
  String get bloodNoMyRequests;

  /// No description provided for @bloodRequestAction.
  ///
  /// In en, this message translates to:
  /// **'Request blood'**
  String get bloodRequestAction;

  /// No description provided for @bloodUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get bloodUrgent;

  /// No description provided for @bloodUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bag} other{{count} bags}}'**
  String bloodUnits(int count);

  /// No description provided for @bloodNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'{group} blood needed'**
  String bloodNeededTitle(String group);

  /// No description provided for @bloodToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String bloodToday(String time);

  /// No description provided for @bloodTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String bloodTomorrow(String time);

  /// No description provided for @bloodStatusFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Got blood'**
  String get bloodStatusFulfilled;

  /// No description provided for @bloodStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bloodStatusClosed;

  /// No description provided for @bloodStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bloodStatusExpired;

  /// No description provided for @bloodResponses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No donors yet} =1{1 donor can help} other{{count} donors can help}}'**
  String bloodResponses(int count);

  /// No description provided for @bloodNotified.
  ///
  /// In en, this message translates to:
  /// **'{count} {group} donors were notified'**
  String bloodNotified(int count, String group);

  /// No description provided for @bloodMatching.
  ///
  /// In en, this message translates to:
  /// **'{count} {group} donors at your university'**
  String bloodMatching(int count, String group);

  /// No description provided for @bloodCompatible.
  ///
  /// In en, this message translates to:
  /// **'Can also receive from: {groups}'**
  String bloodCompatible(String groups);

  /// No description provided for @bloodContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get bloodContact;

  /// No description provided for @bloodCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get bloodCall;

  /// No description provided for @bloodPhoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get bloodPhoneCopied;

  /// No description provided for @bloodICanDonate.
  ///
  /// In en, this message translates to:
  /// **'I can donate'**
  String get bloodICanDonate;

  /// No description provided for @bloodWithdraw.
  ///
  /// In en, this message translates to:
  /// **'I can\'t any more'**
  String get bloodWithdraw;

  /// No description provided for @bloodYouOffered.
  ///
  /// In en, this message translates to:
  /// **'You offered to donate'**
  String get bloodYouOffered;

  /// No description provided for @bloodRespondTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer to donate?'**
  String get bloodRespondTitle;

  /// No description provided for @bloodRespondBody.
  ///
  /// In en, this message translates to:
  /// **'Your name, blood group and phone number go to {name}, who will call you.'**
  String bloodRespondBody(String name);

  /// No description provided for @bloodRespondSend.
  ///
  /// In en, this message translates to:
  /// **'Send my number'**
  String get bloodRespondSend;

  /// No description provided for @bloodResponded.
  ///
  /// In en, this message translates to:
  /// **'Thank you! {name} can now call you.'**
  String bloodResponded(String name);

  /// No description provided for @bloodNotYourGroup.
  ///
  /// In en, this message translates to:
  /// **'This request needs {group}; you are {mine}.'**
  String bloodNotYourGroup(String group, String mine);

  /// No description provided for @bloodGotBlood.
  ///
  /// In en, this message translates to:
  /// **'Got blood'**
  String get bloodGotBlood;

  /// No description provided for @bloodCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get bloodCancelRequest;

  /// No description provided for @bloodCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request? Donors won\'t see it any more.'**
  String get bloodCancelConfirm;

  /// No description provided for @bloodClosedThanks.
  ///
  /// In en, this message translates to:
  /// **'Glad you got help. Take care!'**
  String get bloodClosedThanks;

  /// No description provided for @bloodGroupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Blood group needed'**
  String get bloodGroupNeeded;

  /// No description provided for @bloodUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get bloodUnitsLabel;

  /// No description provided for @bloodHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get bloodHospital;

  /// No description provided for @bloodHospitalHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Enam Medical College Hospital'**
  String get bloodHospitalHint;

  /// No description provided for @bloodArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get bloodArea;

  /// No description provided for @bloodAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Savar'**
  String get bloodAreaHint;

  /// No description provided for @bloodWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get bloodWhen;

  /// No description provided for @bloodWhenToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bloodWhenToday;

  /// No description provided for @bloodWhenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get bloodWhenTomorrow;

  /// No description provided for @bloodWhenPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get bloodWhenPick;

  /// No description provided for @bloodUrgentHint.
  ///
  /// In en, this message translates to:
  /// **'Needed within a few hours'**
  String get bloodUrgentHint;

  /// No description provided for @bloodContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get bloodContactName;

  /// No description provided for @bloodContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get bloodContactPhone;

  /// No description provided for @bloodNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get bloodNote;

  /// No description provided for @bloodNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Thalassemia patient, surgery at 10 AM'**
  String get bloodNoteHint;

  /// No description provided for @bloodPost.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get bloodPost;

  /// No description provided for @bloodPostedNone.
  ///
  /// In en, this message translates to:
  /// **'Posted. Share it too: no {group} donors have joined here yet.'**
  String bloodPostedNone(String group);

  /// No description provided for @bloodVerifyFirst.
  ///
  /// In en, this message translates to:
  /// **'Verify your university email to ask for blood. This keeps requests real.'**
  String get bloodVerifyFirst;

  /// No description provided for @bloodShareIntro.
  ///
  /// In en, this message translates to:
  /// **'🩸 {group} blood needed'**
  String bloodShareIntro(String group);

  /// No description provided for @bloodShareVia.
  ///
  /// In en, this message translates to:
  /// **'Via VarsityKotha: {link}'**
  String bloodShareVia(String link);

  /// No description provided for @errorVerifyRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your university email first.'**
  String get errorVerifyRequired;

  /// No description provided for @errorTooManyOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'You already have 3 open requests. Close one first.'**
  String get errorTooManyOpenRequests;

  /// No description provided for @errorBloodRequestNotFound.
  ///
  /// In en, this message translates to:
  /// **'This request isn\'t available any more.'**
  String get errorBloodRequestNotFound;

  /// No description provided for @errorRequestClosed.
  ///
  /// In en, this message translates to:
  /// **'This request is closed.'**
  String get errorRequestClosed;

  /// No description provided for @errorCannotRespondOwn.
  ///
  /// In en, this message translates to:
  /// **'This is your own request.'**
  String get errorCannotRespondOwn;

  /// No description provided for @errorDonorRequired.
  ///
  /// In en, this message translates to:
  /// **'Set up your donor profile first.'**
  String get errorDonorRequired;

  /// No description provided for @visitSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search universities'**
  String get visitSearchHint;

  /// No description provided for @visitMostActive.
  ///
  /// In en, this message translates to:
  /// **'Most active this week'**
  String get visitMostActive;

  /// No description provided for @visitStudents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String visitStudents(int count);

  /// No description provided for @visitPostsWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No posts this week} =1{1 post this week} other{{count} posts this week}}'**
  String visitPostsWeek(int count);

  /// No description provided for @visitClassGroups.
  ///
  /// In en, this message translates to:
  /// **'Class groups'**
  String get visitClassGroups;

  /// No description provided for @visitBusRoutes.
  ///
  /// In en, this message translates to:
  /// **'Bus routes'**
  String get visitBusRoutes;

  /// No description provided for @visitStudentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get visitStudentsLabel;

  /// No description provided for @visitPostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Posts this week'**
  String get visitPostsLabel;

  /// No description provided for @visitPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visitPublic;

  /// No description provided for @visitPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visitPrivate;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get visitWebsite;

  /// No description provided for @visitYouAreVisiting.
  ///
  /// In en, this message translates to:
  /// **'You\'re visiting {name}. Only its students can comment.'**
  String visitYouAreVisiting(String name);

  /// No description provided for @visitEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts here yet'**
  String get visitEmpty;

  /// No description provided for @visitEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Its students haven\'t posted anything yet.'**
  String get visitEmptyHint;

  /// No description provided for @visitNoCampuses.
  ///
  /// In en, this message translates to:
  /// **'No university matches'**
  String get visitNoCampuses;

  /// No description provided for @visitYourCampus.
  ///
  /// In en, this message translates to:
  /// **'Your campus'**
  String get visitYourCampus;

  /// No description provided for @campusOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Only my university'**
  String get campusOnlyLabel;

  /// No description provided for @campusOnlyOn.
  ///
  /// In en, this message translates to:
  /// **'Only students of your university can see this.'**
  String get campusOnlyOn;

  /// No description provided for @campusOnlyOff.
  ///
  /// In en, this message translates to:
  /// **'Students of all universities can see this (they can\'t comment).'**
  String get campusOnlyOff;

  /// No description provided for @campusOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'My university only'**
  String get campusOnlyBadge;

  /// No description provided for @voiceAnon9.
  ///
  /// In en, this message translates to:
  /// **'Posts, questions and polls can be read by students of other universities, unless you choose \"Only my university\". Issues and safety reports stay inside your university.'**
  String get voiceAnon9;

  /// No description provided for @errorVisitorReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Only students of this university can do that.'**
  String get errorVisitorReadOnly;

  /// No description provided for @errorUniversityGone.
  ///
  /// In en, this message translates to:
  /// **'This university isn\'t on VarsityKotha.'**
  String get errorUniversityGone;

  /// No description provided for @visitReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'You\'re visiting another university: read and react; only its students can comment.'**
  String get visitReadOnlyNote;
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
