import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Every icon in the app, by meaning, from the Phosphor family (regular
/// weight; filled for selected tabs and "on" states). Change an icon here,
/// not at its uses, so the app stays consistent.
abstract final class CsIcons {
  static const IconData academic = PhosphorIconsRegular.graduationCap;
  static const IconData add = PhosphorIconsRegular.plus;
  static const IconData addCircle = PhosphorIconsRegular.plusCircle;
  static const IconData addPhoto = PhosphorIconsRegular.camera;
  static const IconData alarm = PhosphorIconsRegular.alarm;
  static const IconData anonymous = PhosphorIconsRegular.detective;
  static const IconData anonymousFill = PhosphorIconsFill.detective;
  static const IconData arrowDown = PhosphorIconsRegular.arrowDown;
  static const IconData arrowLeft = PhosphorIconsRegular.arrowLeft;
  static const IconData arrowRight = PhosphorIconsRegular.arrowRight;
  static const IconData arrowUp = PhosphorIconsRegular.arrowUp;
  static const IconData assignment = PhosphorIconsRegular.fileText;
  static const IconData battery = PhosphorIconsRegular.batteryWarning;
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData bellActive = PhosphorIconsFill.bellRinging;
  static const IconData blocked = PhosphorIconsRegular.prohibit;
  static const IconData bus = PhosphorIconsRegular.bus;
  static const IconData calendar = PhosphorIconsRegular.calendarDots;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData call = PhosphorIconsRegular.phoneCall;
  static const IconData campus = PhosphorIconsRegular.chatsCircle;
  static const IconData campusFill = PhosphorIconsFill.chatsCircle;
  static const IconData cancelClass = PhosphorIconsRegular.calendarX;
  static const IconData cgpa = PhosphorIconsRegular.calculator;
  static const IconData changeDay = PhosphorIconsRegular.calendarPlus;
  static const IconData changeStatus = PhosphorIconsRegular.arrowsClockwise;
  static const IconData checkCircle = PhosphorIconsFill.checkCircle;
  static const IconData chevronRight = PhosphorIconsRegular.caretRight;
  static const IconData circle = PhosphorIconsRegular.circle;
  static const IconData clear = PhosphorIconsFill.xCircle;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData code = PhosphorIconsRegular.hash;
  static const IconData comment = PhosphorIconsRegular.chatCircle;
  static const IconData construction = PhosphorIconsRegular.hammer;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData course = PhosphorIconsRegular.bookOpenText;
  static const IconData dark = PhosphorIconsRegular.moon;
  static const IconData date = PhosphorIconsRegular.calendarBlank;
  static const IconData dateCheck = PhosphorIconsRegular.calendarCheck;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData department = PhosphorIconsRegular.buildings;
  static const IconData details = PhosphorIconsRegular.textAlignLeft;
  static const IconData directions = PhosphorIconsRegular.navigationArrow;
  static const IconData doneForToday = PhosphorIconsRegular.coffee;
  static const IconData dragHandle = PhosphorIconsRegular.dotsSixVertical;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData editNote = PhosphorIconsRegular.notePencil;
  static const IconData email = PhosphorIconsRegular.envelopeSimple;
  static const IconData emailAt = PhosphorIconsRegular.at;
  static const IconData emailSent = PhosphorIconsRegular.envelopeOpen;
  static const IconData error = PhosphorIconsRegular.warningCircle;
  static const IconData explore = PhosphorIconsRegular.squaresFour;
  static const IconData exploreFill = PhosphorIconsFill.squaresFour;
  static const IconData flag = PhosphorIconsFill.flagBanner;
  static const IconData food = PhosphorIconsRegular.forkKnife;
  static const IconData gallery = PhosphorIconsRegular.images;
  static const IconData groups = PhosphorIconsRegular.usersThree;
  static const IconData help = PhosphorIconsRegular.question;
  static const IconData hidden = PhosphorIconsRegular.eyeSlash;
  static const IconData history = PhosphorIconsRegular.clockCounterClockwise;
  static const IconData hostel = PhosphorIconsRegular.bed;
  static const IconData idCard = PhosphorIconsRegular.identificationBadge;
  static const IconData image = PhosphorIconsRegular.image;
  static const IconData imageBroken = PhosphorIconsRegular.imageBroken;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData invite = PhosphorIconsRegular.userPlus;
  static const IconData key = PhosphorIconsRegular.key;
  static const IconData lab = PhosphorIconsRegular.flask;
  static const IconData language = PhosphorIconsRegular.translate;
  static const IconData light = PhosphorIconsRegular.sun;
  static const IconData listAdd = PhosphorIconsRegular.listPlus;
  static const IconData lock = PhosphorIconsRegular.lock;
  static const IconData maintenance = PhosphorIconsRegular.wrench;

  /// Three-dot menus (Flutter's default is a Material icon).
  static const IconData map = PhosphorIconsRegular.mapTrifold;
  static const IconData more = PhosphorIconsBold.dotsThreeVertical;
  static const IconData members = PhosphorIconsRegular.users;
  static const IconData meToo = PhosphorIconsRegular.handPalm;
  static const IconData meTooFill = PhosphorIconsFill.handPalm;
  static const IconData myCourses = PhosphorIconsRegular.listChecks;
  static const IconData myIssues = PhosphorIconsRegular.clipboardText;
  static const IconData newSemester = PhosphorIconsRegular.repeat;
  static const IconData note = PhosphorIconsRegular.note;
  static const IconData offline = PhosphorIconsRegular.cloudSlash;
  static const IconData openExternal = PhosphorIconsRegular.arrowSquareOut;
  static const IconData paste = PhosphorIconsRegular.clipboard;
  static const IconData pending = PhosphorIconsRegular.hourglassMedium;
  static const IconData phone = PhosphorIconsRegular.deviceMobile;
  static const IconData pin = PhosphorIconsFill.pushPin;
  static const IconData place = PhosphorIconsRegular.mapPin;
  static const IconData placeAdd = PhosphorIconsRegular.mapPinPlus;
  static const IconData placeFill = PhosphorIconsFill.mapPin;
  static const IconData presentation = PhosphorIconsRegular.presentationChart;
  static const IconData privacy = PhosphorIconsRegular.shieldCheck;
  static const IconData profile = PhosphorIconsRegular.user;
  static const IconData profileFill = PhosphorIconsFill.user;
  static const IconData raiseIssue = PhosphorIconsRegular.megaphone;
  static const IconData rankings = PhosphorIconsRegular.ranking;
  static const IconData refresh = PhosphorIconsRegular.arrowClockwise;
  static const IconData reminders = PhosphorIconsRegular.bellRinging;
  static const IconData room = PhosphorIconsRegular.door;
  static const IconData routine = PhosphorIconsRegular.calendarDots;
  static const IconData routineFill = PhosphorIconsFill.calendarDots;
  static const IconData routineNote = PhosphorIconsRegular.calendarDots;
  static const IconData rules = PhosphorIconsRegular.gavel;
  static const IconData safety = PhosphorIconsRegular.shieldWarning;
  static const IconData scale = PhosphorIconsRegular.slidersHorizontal;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData searchEmpty = PhosphorIconsRegular.magnifyingGlassMinus;
  static const IconData send = PhosphorIconsRegular.paperPlaneRight;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData signOut = PhosphorIconsRegular.signOut;
  static const IconData sparkle = PhosphorIconsRegular.sparkle;
  static const IconData star = PhosphorIconsFill.star;
  static const IconData swap = PhosphorIconsRegular.arrowsLeftRight;
  static const IconData sync = PhosphorIconsRegular.arrowsClockwise;
  static const IconData target = PhosphorIconsRegular.target;
  static const IconData teacherReviews = PhosphorIconsRegular.chalkboardTeacher;
  static const IconData test = PhosphorIconsRegular.exam;
  static const IconData theme = PhosphorIconsRegular.palette;
  static const IconData themeSystem = PhosphorIconsRegular.circleHalf;
  static const IconData time = PhosphorIconsRegular.clock;
  static const IconData today = PhosphorIconsRegular.house;
  static const IconData todayFill = PhosphorIconsFill.house;
  static const IconData trending = PhosphorIconsRegular.trendUp;
  static const IconData undo = PhosphorIconsRegular.arrowCounterClockwise;
  static const IconData university = PhosphorIconsRegular.bank;
  static const IconData update = PhosphorIconsRegular.downloadSimple;
  static const IconData verified = PhosphorIconsFill.sealCheck;
  static const IconData verifiedOutline = PhosphorIconsRegular.sealCheck;
  static const IconData visible = PhosphorIconsRegular.eye;
  static const IconData visitCampus = PhosphorIconsRegular.globeHemisphereEast;
  static const IconData warning = PhosphorIconsRegular.warning;
  static const IconData wifi = PhosphorIconsRegular.wifiHigh;

  // Campus social (docs/CAMPUS_SOCIAL.md).
  static const IconData buySell = PhosphorIconsRegular.tag;
  static const IconData event = PhosphorIconsRegular.confetti;
  static const IconData fun = PhosphorIconsRegular.smiley;
  static const IconData general = PhosphorIconsRegular.chatsCircle;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData heartFill = PhosphorIconsFill.heart;
  static const IconData lostFound = PhosphorIconsRegular.binoculars;
  static const IconData poll = PhosphorIconsRegular.chartBarHorizontal;
  static const IconData post = PhosphorIconsRegular.notePencil;
  static const IconData question = PhosphorIconsRegular.sealQuestion;
  static const IconData reply = PhosphorIconsRegular.arrowBendUpLeft;
  static const IconData share = PhosphorIconsRegular.shareFat;
  static const IconData folder = PhosphorIconsRegular.folderOpen;
  static const IconData blood = PhosphorIconsRegular.drop;
  static const IconData bloodFill = PhosphorIconsFill.drop;

  // Live buses.
  static const IconData live = PhosphorIconsRegular.broadcast;
  static const IconData stopSharing = PhosphorIconsRegular.stopCircle;
  static const IconData crowded = PhosphorIconsRegular.usersFour;
  static const IconData late = PhosphorIconsRegular.clockCountdown;
  static const IconData thanks = PhosphorIconsRegular.handshake;

  // Growth: prizes and badges.
  static const IconData trophy = PhosphorIconsRegular.trophy;
  static const IconData gift = PhosphorIconsRegular.gift;
  static const IconData timer = PhosphorIconsRegular.timer;

  /// The picture of a badge, by its key; a medal for keys this app doesn't
  /// know yet.
  static IconData badge(String key) => switch (key) {
    'verified' => PhosphorIconsFill.sealCheck,
    'founding' => PhosphorIconsRegular.rocketLaunch,
    'cr' => PhosphorIconsRegular.crown,
    'campus_admin' => PhosphorIconsRegular.shieldCheck,
    'bus_rep' => PhosphorIconsRegular.bus,
    'official' => PhosphorIconsRegular.buildings,
    'blood_donor' => PhosphorIconsRegular.drop,
    'life_saver' => PhosphorIconsRegular.heartbeat,
    'bus_buddy' => PhosphorIconsRegular.mapPin,
    'section_builder' => PhosphorIconsRegular.usersThree,
    'connector' => PhosphorIconsRegular.shareNetwork,
    'bug_hunter' => PhosphorIconsRegular.bug,
    'helper' => PhosphorIconsRegular.handHeart,
    'campus_voice' => PhosphorIconsRegular.megaphone,
    _ => PhosphorIconsRegular.medal,
  };

  /// The filled emblem on a badge medal.
  static IconData badgeFill(String key) => switch (key) {
    'verified' => PhosphorIconsFill.sealCheck,
    'founding' => PhosphorIconsFill.rocketLaunch,
    'cr' => PhosphorIconsFill.crown,
    'campus_admin' => PhosphorIconsFill.shieldCheck,
    'bus_rep' => PhosphorIconsFill.bus,
    'official' => PhosphorIconsFill.buildings,
    'blood_donor' => PhosphorIconsFill.drop,
    'life_saver' => PhosphorIconsFill.heartbeat,
    'bus_buddy' => PhosphorIconsFill.mapPin,
    'section_builder' => PhosphorIconsFill.usersThree,
    'connector' => PhosphorIconsFill.shareNetwork,
    'bug_hunter' => PhosphorIconsFill.bug,
    'helper' => PhosphorIconsFill.handHeart,
    'campus_voice' => PhosphorIconsFill.megaphone,
    _ => PhosphorIconsFill.medal,
  };
}
