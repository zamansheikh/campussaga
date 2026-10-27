// Renders every screen with real fonts (Roboto, Material icons, Noto Sans
// Bengali) in light, dark and Bangla, and writes PNG contact sheets, for
// design review. Not part of `flutter test`; run it on purpose:
//
//   flutter test tool/screenshots/screens_test.dart \
//     --dart-define=SHOTS_DIR=/absolute/output/dir
//
// Needs the Flutter SDK's bundled Material fonts (bin/cache/artifacts).
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_core/campus_core.dart';
import 'package:campussaga/app/app.dart';
import 'package:campussaga/app/clock.dart';
import 'package:campussaga/app/router.dart';
import 'package:campussaga/app/settings/bloc/settings_state.dart';
import 'package:campussaga/app/settings/settings_storage.dart';
import 'package:campussaga/features/reminders/data/reminder_scheduler.dart';
import 'package:campussaga/features/reminders/data/reminder_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../test/helpers/fakes.dart';

const _outDir = String.fromEnvironment('SHOTS_DIR');
const _scale = 1.25; // output pixels per logical pixel

const _student = UserProfile(
  id: 'u1',
  email: 'rafiul.islam@diu.edu.bd',
  university: University(
    id: 'uni1',
    slug: 'diu',
    name: 'Daffodil International University',
    nameBn: 'ড্যাফোডিল ইন্টারন্যাশনাল ইউনিভার্সিটি',
  ),
  role: 'student',
  displayName: 'Rafiul Islam',
  department: 'CSE',
  batch: '61',
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

ClassGroup _group(GroupRole role) => ClassGroup(
  id: 'g1',
  department: 'CSE',
  batch: '61',
  section: 'A',
  semester: 'Fall 2026',
  joinCode: 'KQWZRT',
  role: role,
  memberCount: 42,
  slots: [
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
    _c('7', 'ENG102', 'Technical Writing', 4, '11:30', '13:00', room: '305'),
  ],
);

const _newStudent = UserProfile(
  id: 'u2',
  email: 'nabila@diu.edu.bd',
  university: University(
    id: 'uni1',
    slug: 'diu',
    name: 'Daffodil International University',
    nameBn: 'ড্যাফোডিল ইন্টারন্যাশনাল ইউনিভার্সিটি',
  ),
  role: 'student',
  displayName: 'Nabila Rahman',
);

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final material = '${sdk.path}/artifacts/material_fonts';
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  // Text with no family (button labels) uses the test font in tests and
  // the system font on phones: map both to Roboto here.
  for (final name in ['Roboto', 'FlutterTest']) {
    await family(name, [
      for (final w in ['Regular', 'Medium', 'Bold']) '$material/Roboto-$w.ttf',
    ]);
  }
  await family('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  const bn = '../../packages/campus_ui/fonts/NotoSansBengali';
  await family('packages/campus_ui/NotoSansBengali', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$bn/NotoSansBengali-$w.ttf',
  ]);
}

class _Look {
  const _Look(this.name, this.theme, this.locale);
  final String name;
  final ThemeMode theme;
  final String locale;
}

const _looks = [
  _Look('light-en', ThemeMode.light, 'en'),
  _Look('dark-en', ThemeMode.dark, 'en'),
  _Look('light-bn', ThemeMode.light, 'bn'),
];

void main() {
  final shots = <String, List<ui.Image>>{};

  setUpAll(_loadFonts);

  tearDownAll(() async {
    if (_outDir.isEmpty) return;
    Directory(_outDir).createSync(recursive: true);
    for (final MapEntry(key: name, value: images) in shots.entries) {
      final png = await _sheet(images);
      File('$_outDir/$name.png').writeAsBytesSync(png);
    }
  });

  Future<void> capture(WidgetTester tester, String sheet) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: _scale),
    );
    (shots[sheet] ??= []).add(image!);
  }

  Future<GoRouter> start(
    WidgetTester tester,
    _Look look, {
    UserProfile? user,
    bool onboarded = true,
    List<ClassGroup> groups = const [],
    Map<String, ClassGroup> others = const {},
    ReminderSettings reminders = const ReminderSettings(),
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (repo, _) = await registerFakes(
      reminderStore: MemoryReminderStore(reminders),
      reminderScheduler: MemoryReminderScheduler()
        ..granted = reminders.enabled
        ..exact = false,
      classes: FakeClassGroupRepository()
        ..mine.addAll(groups)
        ..others.addAll(others),
      settings: MemorySettingsStorage(
        SettingsState(
          themeMode: look.theme,
          locale: Locale(look.locale),
          onboardingDone: onboarded,
        ),
      ),
      profile: FakeProfileRepository(),
    );
    repo
      ..savedUser = user
      ..googleUser = _student;
    await tester.pumpWidget(
      RepaintBoundary(key: _boundaryKey, child: const CampusApp()),
    );
    await tester.pumpAndSettle();
    return GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  setUp(() => appNow = () => DateTime(2026, 10, 27, 10, 5));
  tearDown(() => appNow = DateTime.now);

  for (final look in _looks) {
    shot('classes ${look.name}', (tester) async {
      final router = await start(
        tester,
        look,
        user: _student,
        groups: [_group(GroupRole.cr)],
      );
      await capture(tester, 'classes-${look.name}');
      router.go(Routes.routine);
      await tester.pumpAndSettle();
      await capture(tester, 'classes-${look.name}');
      unawaited(router.push(Routes.group('g1')));
      await tester.pumpAndSettle();
      await capture(tester, 'classes-${look.name}');
      unawaited(router.push(Routes.editSlot('g1', '4')));
      await tester.pumpAndSettle();
      await capture(tester, 'classes-${look.name}');
    });

    shot('reminders ${look.name}', (tester) async {
      await start(
        tester,
        look,
        user: _student,
        groups: [_group(GroupRole.member)],
      );
      await capture(tester, 'reminders-${look.name}');
      await tester.pumpWidget(const SizedBox());
      final router = await start(
        tester,
        look,
        user: _student,
        groups: [_group(GroupRole.member)],
        reminders: const ReminderSettings(
          enabled: true,
          asked: true,
          muted: {'ENG102'},
        ),
      );
      unawaited(router.push(Routes.reminders));
      await tester.pumpAndSettle();
      await capture(tester, 'reminders-${look.name}');
    });

    shot('join ${look.name}', (tester) async {
      final router = await start(
        tester,
        look,
        user: _student,
        others: {'KQWZRT': _group(GroupRole.member)},
      );
      await capture(tester, 'join-${look.name}');
      unawaited(router.push(Routes.joinGroup));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'KQWZRT');
      await tester.pumpAndSettle();
      await capture(tester, 'join-${look.name}');
      unawaited(router.push(Routes.newGroup));
      await tester.pumpAndSettle();
      await capture(tester, 'join-${look.name}');
    });

    shot('onboarding ${look.name}', (tester) async {
      await start(tester, look, onboarded: false);
      for (var i = 0; i < 3; i++) {
        await capture(tester, 'onboarding');
        if (i < 2) {
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();
        }
      }
    });

    shot('sign-in ${look.name}', (tester) async {
      final router = await start(tester, look);
      await capture(tester, 'sign-in-${look.name}');
      unawaited(router.push(Routes.signInEmail));
      await tester.pumpAndSettle();
      await capture(tester, 'sign-in-${look.name}');
      await tester.enterText(find.byType(TextField), 'rafiul.islam@diu.edu.bd');
      await tester.tap(find.byType(FilledButton));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '0000');
      await settle(tester);
      await capture(tester, 'sign-in-${look.name}');
      await tester.pumpWidget(const SizedBox()); // stops the countdown
    });

    shot('setup ${look.name}', (tester) async {
      await start(tester, look, user: _newStudent);
      await capture(tester, 'home-${look.name}');
    });

    shot('home ${look.name}', (tester) async {
      final router = await start(tester, look, user: _student);
      await capture(tester, 'home-${look.name}');
      router.go(Routes.routine);
      await tester.pumpAndSettle();
      await capture(tester, 'home-${look.name}');
      router.go(Routes.profile);
      await tester.pumpAndSettle();
      await capture(tester, 'profile-${look.name}');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      await capture(tester, 'profile-${look.name}');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      await capture(tester, 'profile-${look.name}');
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      unawaited(router.push(Routes.editProfile));
      await tester.pumpAndSettle();
      await capture(tester, 'profile-${look.name}');
    });
  }
}

final _boundaryKey = GlobalKey();

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

/// Puts the screenshots side by side on one image.
Future<List<int>> _sheet(List<ui.Image> images) async {
  const gap = 24.0;
  final w = images.first.width.toDouble();
  final h = images.first.height.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, images.length * (w + gap) + gap, h + 2 * gap),
      Paint()..color = const Color(0xFF6B7280),
    );
  for (var i = 0; i < images.length; i++) {
    canvas.drawImage(images[i], Offset(gap + i * (w + gap), gap), Paint());
  }
  final sheet = await recorder.endRecording().toImage(
    (images.length * (w + gap) + gap).round(),
    (h + 2 * gap).round(),
  );
  final data = await sheet.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
