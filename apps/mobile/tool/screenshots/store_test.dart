// Renders the screens used for the Google Play listing, one PNG per screen
// (1170 x 2532, a 390 x 844 phone at 3x), in English and Bangla. The store
// frames and captions are added afterwards by tool/store/ (see
// docs/PLAY_STORE.md). Not part of `flutter test`; run it on purpose:
//
//   flutter test tool/screenshots/store_test.dart \
//     --dart-define=SHOTS_DIR=/absolute/output/dir
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_core/campus_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:varsitykotha/app/app.dart';
import 'package:varsitykotha/app/clock.dart';
import 'package:varsitykotha/app/di.dart';
import 'package:varsitykotha/app/router.dart';
import 'package:varsitykotha/app/settings/bloc/settings_state.dart';
import 'package:varsitykotha/app/settings/settings_storage.dart';
import 'package:varsitykotha/features/cgpa/data/cgpa_store.dart';
import 'package:varsitykotha/features/reminders/data/reminder_scheduler.dart';
import 'package:varsitykotha/features/reminders/data/reminder_store.dart';
import 'package:varsitykotha/features/transport/data/transport_store.dart';
import 'package:varsitykotha/features/transport/presentation/bus_cubit.dart';

import '../../test/bus_routes_test.dart' show FakeTransportRepository;
import '../../test/helpers/fakes.dart';
import '../../test/voice_fakes.dart';

const _outDir = String.fromEnvironment('SHOTS_DIR');

const _uni = University(
  id: 'uni1',
  slug: 'diu',
  name: 'Daffodil International University',
  nameBn: 'ড্যাফোডিল ইন্টারন্যাশনাল ইউনিভার্সিটি',
);

const _student = UserProfile(
  id: 'u1',
  email: 'rafiul.islam@diu.edu.bd',
  university: _uni,
  role: 'student',
  displayName: 'Rafiul Islam',
  department: 'CSE',
  batch: '61',
  verified: true,
);

ClassSlot _c(
  String id,
  String code,
  String title,
  int day,
  String start,
  String end, {
  String room = '',
  String teacher = '',
  ClassKind kind = ClassKind.theory,
}) => ClassSlot(
  id: id,
  courseCode: code,
  courseTitle: title,
  teacher: teacher,
  room: room,
  weekday: day,
  startMin: Clock.parse(start),
  endMin: Clock.parse(end),
  kind: kind,
);

final _slots = [
  _c(
    '1',
    'CSE311',
    'Database Systems',
    6,
    '08:30',
    '10:00',
    room: '504',
    teacher: 'Dr. Rahman',
  ),
  _c(
    '2',
    'CSE313',
    'Operating Systems',
    6,
    '10:00',
    '11:30',
    room: '602',
    teacher: 'Nusrat Jahan',
  ),
  _c(
    '3',
    'CSE311',
    'Database Systems',
    2,
    '08:30',
    '10:00',
    room: '504',
    teacher: 'Dr. Rahman',
  ),
  _c(
    '4',
    'CSE312',
    'Database Lab',
    2,
    '10:30',
    '13:30',
    room: 'Lab 3',
    teacher: 'Dr. Rahman',
    kind: ClassKind.lab,
  ),
  _c(
    '5',
    'MAT201',
    'Linear Algebra',
    2,
    '14:30',
    '16:00',
    room: '410',
    teacher: 'Kamrul Hasan',
  ),
  _c(
    '6',
    'CSE313',
    'Operating Systems',
    3,
    '09:00',
    '10:30',
    room: '602',
    teacher: 'Nusrat Jahan',
  ),
  _c(
    '7',
    'ENG102',
    'Technical Writing',
    4,
    '11:30',
    '13:00',
    room: '305',
    teacher: 'Farhana Akter',
  ),
  _c(
    '8',
    'CSE315',
    'Software Engineering',
    7,
    '13:00',
    '14:30',
    room: '702',
    teacher: 'Mahmudul Hasan',
  ),
  _c(
    '9',
    'CSE311',
    'Database Systems',
    1,
    '10:00',
    '11:30',
    room: '504',
    teacher: 'Dr. Rahman',
  ),
  _c(
    '10',
    'MAT201',
    'Linear Algebra',
    4,
    '08:30',
    '10:00',
    room: '410',
    teacher: 'Kamrul Hasan',
  ),
];

ClassGroup _group({
  String id = 'g1',
  String department = 'CSE',
  String batch = '61',
  String section = 'A',
  String code = 'KQWZRT',
  GroupRole role = GroupRole.member,
  int members = 42,
}) => ClassGroup(
  id: id,
  department: department,
  batch: batch,
  section: section,
  semester: 'Fall 2026',
  joinCode: code,
  role: role,
  memberCount: members,
  slots: _slots,
);

DateTime _d(int day) => DateTime(2026, 10, day);

/// The student's class group on a busy Tuesday: a moved lab, a cancelled
/// class, tests coming up and a pinned announcement.
ClassGroup _busyGroup() => _group().copyWith(
  changes: [
    ClassChange(
      id: 'c1',
      kind: ChangeKind.moved,
      slotId: '4',
      date: _d(27),
      startMin: 11 * 60,
      endMin: 14 * 60,
      room: 'Lab 5',
      note: _t('Lab 3 projector is broken', 'ল্যাব ৩-এর প্রজেক্টর নষ্ট'),
    ),
    ClassChange(
      id: 'm1',
      kind: ChangeKind.moved,
      slotId: '5',
      date: _d(27),
      newDate: _d(29),
      startMin: 9 * 60,
      endMin: 10 * 60 + 30,
      room: '410',
      note: _t(
        'The teacher is at a seminar on Tuesday',
        'মঙ্গলবার স্যার সেমিনারে থাকবেন',
      ),
    ),
  ],
  assessments: [
    Assessment(
      id: 't2',
      kind: AssessmentKind.quiz,
      courseCode: 'CSE313',
      courseTitle: 'Operating Systems',
      date: _d(28),
      startMin: 9 * 60,
      endMin: 9 * 60 + 20,
      room: '602',
      topics: _t(
        'Process scheduling, chapters 3–5',
        'প্রসেস শিডিউলিং, অধ্যায় ৩–৫',
      ),
      createdById: 'u1',
      createdByName: 'Rafiul Islam',
    ),
    Assessment(
      id: 't3',
      kind: AssessmentKind.assignment,
      courseCode: 'ENG102',
      courseTitle: 'Technical Writing',
      date: _d(29),
      startMin: 23 * 60 + 59,
      topics: _t(
        'Report on a campus problem, 800 words',
        'ক্যাম্পাসের একটি সমস্যা নিয়ে রিপোর্ট, ৮০০ শব্দ',
      ),
    ),
    Assessment(
      id: 't4',
      kind: AssessmentKind.midterm,
      courseCode: 'CSE311',
      courseTitle: 'Database Systems',
      date: _d(31),
      startMin: 10 * 60,
      endMin: 11 * 60 + 30,
      room: '504',
    ),
  ],
  announcements: [
    Announcement(
      id: 'a1',
      body: _t(
        'Mid-term exam on 31 October, Room 504.\nSyllabus: chapters 1–5.',
        'মিডটার্ম পরীক্ষা ৩১ অক্টোবর, রুম ৫০৪।\nসিলেবাস: অধ্যায় ১–৫।',
      ),
      pinned: true,
      createdAt: DateTime(2026, 10, 20, 18),
    ),
    Announcement(
      id: 'a2',
      body: _t(
        'Database Lab moved to Lab 5 today: the projector in Lab 3 is broken.',
        'আজ ডেটাবেজ ল্যাব হবে ল্যাব ৫-এ: ল্যাব ৩-এর প্রজেক্টর নষ্ট।',
      ),
      createdAt: DateTime(2026, 10, 27, 7, 20),
    ),
  ],
);

/// A Campus Voice issue with its own text and place (sampleIssue repeats one).
Issue _issue({
  required String id,
  required String title,
  required String body,
  required String place,
  IssueCategory category = IssueCategory.hostel,
  IssueStatus status = IssueStatus.open,
  int meToo = 0,
  int comments = 0,
  PostAuthor? author,
  List<TimelineEntry> timeline = const [],
  required DateTime createdAt,
}) => Issue(
  card: IssueCard(
    id: id,
    category: category,
    private: false,
    title: title,
    preview: body,
    status: status,
    visibility: ContentVisibility.visible,
    meTooCount: meToo,
    commentCount: comments,
    imageCount: 0,
    voted: false,
    mine: false,
    author: author,
    locationLabel: place,
    createdAt: createdAt,
  ),
  body: body,
  timeline: timeline,
);

FakeVoiceRepository _voice() {
  final v = FakeVoiceRepository()
    ..issues.addAll([
      _issue(
        id: 'i1',
        title: _t(
          'No water on the 3rd floor of Hall 2 since Sunday',
          'হল ২-এর ৩য় তলায় রবিবার থেকে পানি নেই',
        ),
        body: _t(
          'The taps on the 3rd floor have been dry since Sunday morning. We carry water up from the ground floor before every class.',
          'রবিবার সকাল থেকে ৩য় তলার কলে পানি নেই। প্রতিটা ক্লাসের আগে নিচতলা থেকে পানি টেনে আনতে হচ্ছে।',
        ),
        place: _t('Hall 2, 3rd floor', 'হল ২, ৩য় তলা'),
        status: IssueStatus.inProgress,
        meToo: 148,
        comments: 2,
        timeline: [
          TimelineEntry(
            from: IssueStatus.open,
            to: IssueStatus.acknowledged,
            actor: TimelineActor.authority,
            actorTitle: _t(
              'Hall Provost, Shaheed Minar Hall',
              'প্রভোস্ট, শহীদ মিনার হল',
            ),
            createdAt: DateTime(2026, 10, 26, 11),
          ),
          TimelineEntry(
            from: IssueStatus.acknowledged,
            to: IssueStatus.inProgress,
            actor: TimelineActor.authority,
            actorTitle: _t(
              'Hall Provost, Shaheed Minar Hall',
              'প্রভোস্ট, শহীদ মিনার হল',
            ),
            note: _t(
              'A new pump is ordered. Water tankers come at 7 AM and 6 PM until then.',
              'নতুন পাম্প অর্ডার করা হয়েছে। ততদিন সকাল ৭টা ও সন্ধ্যা ৬টায় পানির ট্যাংকার আসবে।',
            ),
            createdAt: DateTime(2026, 10, 27, 9),
          ),
        ],
        createdAt: DateTime(2026, 10, 25, 20),
      ),
      _issue(
        id: 'i2',
        title: _t(
          'Bus 4 leaves Mirpur 10 minutes early every morning',
          'মিরপুরের ৪ নম্বর বাস প্রতিদিন ১০ মিনিট আগে ছেড়ে যায়',
        ),
        body: _t(
          'The 7:30 bus leaves at 7:20, so students who come on time miss it and are late for the 8:30 class.',
          '৭:৩০-এর বাস ছাড়ে ৭:২০-এ, তাই যারা সময়মতো আসে তারা বাস মিস করে আর ৮:৩০-এর ক্লাসে দেরি হয়।',
        ),
        place: _t('Mirpur 10 stop', 'মিরপুর ১০ স্টপ'),
        category: IssueCategory.transport,
        meToo: 61,
        comments: 9,
        createdAt: DateTime(2026, 10, 27, 7, 40),
      ),
      _issue(
        id: 'i3',
        title: _t(
          'Wi-Fi in the library drops every few minutes',
          'লাইব্রেরির ওয়াই-ফাই কয়েক মিনিট পরপর কেটে যায়',
        ),
        body: _t(
          'Fixed: the IT office replaced the access points on the 2nd floor.',
          'সমাধান হয়েছে: আইটি অফিস ২য় তলার অ্যাক্সেস পয়েন্ট বদলে দিয়েছে।',
        ),
        place: _t('Central library', 'কেন্দ্রীয় লাইব্রেরি'),
        category: IssueCategory.it,
        status: IssueStatus.solved,
        meToo: 212,
        comments: 14,
        author: const PostAuthor(name: 'Nabila Rahman', verified: true),
        createdAt: DateTime(2026, 10, 20, 15),
      ),
      _issue(
        id: 'i4',
        title: _t(
          'Canteen prices went up without notice',
          'নোটিশ ছাড়াই ক্যান্টিনের দাম বেড়েছে',
        ),
        body: _t(
          'Rice and chicken went from 80 to 110 taka this week, with no notice on the board.',
          'এই সপ্তাহে ভাত-মুরগি ৮০ টাকা থেকে ১১০ টাকা হয়েছে, বোর্ডে কোনো নোটিশ নেই।',
        ),
        place: _t('Main canteen', 'মূল ক্যান্টিন'),
        category: IssueCategory.food,
        status: IssueStatus.acknowledged,
        meToo: 87,
        comments: 6,
        createdAt: DateTime(2026, 10, 26, 13),
      ),
    ]);
  v.commentsByIssue['i1'] = [
    IssueComment(
      id: 'c1',
      body: _t(
        'Same on the 2nd floor. We fill buckets from the ground floor.',
        'দ্বিতীয় তলাতেও একই অবস্থা। আমরা নিচতলা থেকে বালতিতে পানি আনি।',
      ),
      handle: 'B2XZ',
      createdAt: DateTime(2026, 10, 26, 8),
    ),
    IssueComment(
      id: 'c3',
      kind: CommentKind.official,
      officialTitle: _t(
        'Hall Provost, Shaheed Minar Hall',
        'প্রভোস্ট, শহীদ মিনার হল',
      ),
      author: PostAuthor(
        name: _t('Dr. Abdul Karim', 'ড. আবদুল করিম'),
        verified: true,
      ),
      body: _t(
        'The new pump arrives on Thursday. Tankers will keep coming twice a day.',
        'নতুন পাম্প বৃহস্পতিবার আসবে। ততদিন দিনে দুবার ট্যাংকার আসবে।',
      ),
      createdAt: DateTime(2026, 10, 27, 9, 5),
    ),
  ];
  return v;
}

const _satToThu = {6, 7, 1, 2, 3, 4};

BusRoute _mirpur() => BusRoute(
  id: 'mirpur',
  name: _t('Mirpur – Campus', 'মিরপুর – ক্যাম্পাস'),
  color: '#0F766E',
  notes: _t(
    'Board at the front gate. Show your student ID.',
    'মূল গেট থেকে উঠুন। স্টুডেন্ট আইডি দেখান।',
  ),
  stops: [
    BusStop(
      id: 'm10',
      name: _t('Mirpur 10', 'মিরপুর ১০'),
      landmark: _t('Metro station', 'মেট্রো স্টেশন'),
      toCampusMin: 0,
      fromCampusMin: 55,
    ),
    BusStop(
      id: 'm2',
      name: _t('Mirpur 2', 'মিরপুর ২'),
      landmark: _t('Stadium', 'স্টেডিয়াম'),
      toCampusMin: 10,
      fromCampusMin: 45,
    ),
    BusStop(
      id: 'aga',
      name: _t('Agargaon', 'আগারগাঁও'),
      landmark: _t('IDB Bhaban', 'আইডিবি ভবন'),
      toCampusMin: 25,
      fromCampusMin: 30,
    ),
    BusStop(
      id: 'dha',
      name: _t('Dhanmondi 27', 'ধানমন্ডি ২৭'),
      toCampusMin: 40,
      fromCampusMin: 15,
    ),
    BusStop(
      id: 'cam',
      name: _t('Campus', 'ক্যাম্পাস'),
      landmark: _t('Main gate', 'মূল গেট'),
      toCampusMin: 55,
      fromCampusMin: 0,
    ),
  ],
  trips: [
    BusTrip(
      id: 't1',
      direction: BusDirection.toCampus,
      departsMin: 7 * 60,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 't2',
      direction: BusDirection.toCampus,
      departsMin: 8 * 60 + 30,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 't3',
      direction: BusDirection.toCampus,
      departsMin: 11 * 60,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 't4',
      direction: BusDirection.fromCampus,
      departsMin: 13 * 60 + 30,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 't5',
      direction: BusDirection.fromCampus,
      departsMin: 17 * 60,
      weekdays: _satToThu,
    ),
  ],
);

BusRoute _uttara() => BusRoute(
  id: 'uttara',
  name: _t('Uttara – Campus', 'উত্তরা – ক্যাম্পাস'),
  color: '#B45309',
  stops: [
    BusStop(
      id: 'u',
      name: _t('Uttara Sector 7', 'উত্তরা সেক্টর ৭'),
      toCampusMin: 0,
      fromCampusMin: 70,
    ),
    BusStop(
      id: 'cam',
      name: _t('Campus', 'ক্যাম্পাস'),
      toCampusMin: 70,
      fromCampusMin: 0,
    ),
  ],
  trips: [
    BusTrip(
      id: 'u1',
      direction: BusDirection.toCampus,
      departsMin: 6 * 60 + 45,
      weekdays: _satToThu,
    ),
    BusTrip(
      id: 'u2',
      direction: BusDirection.fromCampus,
      departsMin: 17 * 60,
      weekdays: _satToThu,
    ),
  ],
);

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final material = '${sdk.path}/artifacts/material_fonts';
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  for (final name in ['Roboto', 'FlutterTest']) {
    await family(name, [
      for (final w in ['Regular', 'Medium', 'Bold']) '$material/Roboto-$w.ttf',
    ]);
  }
  await family('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  final config = jsonDecode(
    File('../../.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final phosphor = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((p) => p['name'] == 'phosphoricons_flutter');
  final root = Uri.parse(phosphor['rootUri'] as String).toFilePath();
  for (final (style, file) in [
    ('Regular', 'Phosphor'),
    ('Fill', 'Phosphor-Fill'),
    ('Bold', 'Phosphor-Bold'),
  ]) {
    await family('packages/phosphoricons_flutter/Phosphor$style', [
      '$root/lib/fonts/$file.ttf',
    ]);
  }
  const bn = '../../packages/campus_ui/fonts/NotoSansBengali';
  await family('packages/campus_ui/NotoSansBengali', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$bn/NotoSansBengali-$w.ttf',
  ]);
}

final _boundaryKey = GlobalKey();

/// Demo content follows the screenshot language.
var _bn = false;
String _t(String en, String bn) => _bn ? bn : en;

void main() {
  setUpAll(_loadFonts);
  setUp(() => appNow = () => DateTime(2026, 10, 27, 10, 5));
  tearDown(() => appNow = DateTime.now);

  Future<void> capture(WidgetTester tester, String name) async {
    if (_outDir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes!);
  }

  Future<GoRouter> start(
    WidgetTester tester,
    String locale, {
    ThemeMode theme = ThemeMode.light,
    UserProfile? user = _student,
    List<ClassGroup> groups = const [],
    Map<String, ClassGroup> others = const {},
    FakeVoiceRepository? voice,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (repo, _) = await registerFakes(
      reminderStore: MemoryReminderStore(
        const ReminderSettings(enabled: true, asked: true),
      ),
      reminderScheduler: MemoryReminderScheduler()
        ..granted = true
        ..exact = true,
      classes: FakeClassGroupRepository()
        ..mine.addAll(groups)
        ..others.addAll(others),
      settings: MemorySettingsStorage(
        SettingsState(
          themeMode: theme,
          locale: Locale(locale),
          onboardingDone: true,
        ),
      ),
      profile: FakeProfileRepository(),
      voice: voice,
      config: FakeAppConfigRepository()
        ..config = AppConfig(
          minSupportedBuild: 1,
          features: {'myClass': true, 'campusVoice': voice != null},
        ),
    );
    repo.savedUser = user;
    final transport = FakeTransportRepository(routes: [_mirpur(), _uttara()]);
    final store = MemoryTransportStore();
    getIt
      ..registerSingleton<TransportRepository>(transport)
      ..registerSingleton<TransportStore>(store)
      ..registerSingleton<BusCubit>(BusCubit(transport, store))
      ..registerSingleton<CgpaStore>(
        MemoryCgpaStore()..saved[_student.id] = jsonEncode(_cgpaBook.toJson()),
      );
    await tester.pumpWidget(
      RepaintBoundary(key: _boundaryKey, child: const CampusApp()),
    );
    await tester.pumpAndSettle();
    return GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  for (final locale in ['en', 'bn']) {
    shot('today + routine + class $locale', (tester) async {
      _bn = locale == 'bn';
      final router = await start(tester, locale, groups: [_busyGroup()]);
      await capture(tester, '$locale-01-today');
      router.go(Routes.routine);
      await tester.pumpAndSettle();
      await capture(tester, '$locale-02-routine');
      unawaited(router.push(Routes.group('g1')));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-04-group');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-04-group-tests');
    });

    shot('today scrolled $locale', (tester) async {
      _bn = locale == 'bn';
      await start(tester, locale, groups: [_busyGroup()]);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -380));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-03-today-tests');
    });

    shot('voice $locale', (tester) async {
      _bn = locale == 'bn';
      final router = await start(
        tester,
        locale,
        groups: [_busyGroup()],
        voice: _voice(),
      );
      router.go(Routes.campus);
      await tester.pumpAndSettle();
      await capture(tester, '$locale-05-voice');
      unawaited(router.push(Routes.campusIssue('i1')));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-06-issue');
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-06-issue-reply');
      router.pop();
      await tester.pumpAndSettle();
      unawaited(router.push(Routes.campusAnonymity));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-06-anonymity');
    });

    shot('find class $locale', (tester) async {
      _bn = locale == 'bn';
      final router = await start(
        tester,
        locale,
        others: {
          'KQWZRT': _group(),
          'PLMNKO': _group(id: 'g2', section: 'B', code: 'PLMNKO', members: 38),
          'MNPQRS': _group(
            id: 'g3',
            department: 'EEE',
            batch: '58',
            section: 'B',
            code: 'MNPQRS',
            members: 27,
          ),
          'ZXCVBN': _group(
            id: 'g4',
            department: 'BBA',
            batch: '24',
            section: 'C',
            code: 'ZXCVBN',
            members: 51,
          ),
        },
      );
      unawaited(router.push(Routes.findClass));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-07-find');
      unawaited(router.push(Routes.classPreview('g1', code: 'KQWZRT')));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-07-preview');
    });

    shot('explore $locale', (tester) async {
      _bn = locale == 'bn';
      final router = await start(tester, locale, groups: [_busyGroup()]);
      router.go(Routes.explore);
      await tester.pumpAndSettle();
      await capture(tester, '$locale-08-explore');
      unawaited(router.push(Routes.busRoute('mirpur')));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-08-bus');
      router.pop();
      await tester.pumpAndSettle();
      unawaited(router.push(Routes.cgpa));
      await tester.pumpAndSettle();
      await capture(tester, '$locale-08-cgpa');
    });

    shot('dark $locale', (tester) async {
      _bn = locale == 'bn';
      final router = await start(
        tester,
        locale,
        theme: ThemeMode.dark,
        groups: [_busyGroup()],
      );
      await capture(tester, '$locale-09-today-dark');
      router.go(Routes.routine);
      await tester.pumpAndSettle();
      await capture(tester, '$locale-09-routine-dark');
    });
  }
}

const _cgpaBook = CgpaBook(
  semesters: [
    Semester(
      id: 's1',
      name: 'Spring 2026',
      courses: [
        CgpaCourse(
          id: 'a',
          code: 'CSE101',
          title: 'Structured Programming',
          letter: 'A+',
        ),
        CgpaCourse(id: 'b', code: 'MAT101', title: 'Calculus', letter: 'A-'),
        CgpaCourse(
          id: 'c',
          code: 'PHY101',
          credits: 1.5,
          title: 'Physics Lab',
          letter: 'A',
        ),
        CgpaCourse(id: 'g', code: 'ENG101', title: 'English', letter: 'B+'),
      ],
    ),
    Semester(
      id: 's2',
      name: 'Fall 2026',
      courses: [
        CgpaCourse(
          id: 'd',
          code: 'CSE201',
          title: 'Data Structures',
          letter: 'A',
        ),
        CgpaCourse(
          id: 'e',
          code: 'CSE203',
          title: 'Discrete Mathematics',
          letter: 'A-',
        ),
        CgpaCourse(id: 'f', code: 'EEE201', title: 'Electronics', letter: 'B+'),
      ],
    ),
  ],
);

/// A screenshot test with real shadows (tests draw outlines by default).
void shot(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}
