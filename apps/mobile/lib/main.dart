import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/crash/crash_reporter.dart';
import 'app/di.dart';
import 'features/classes/data/invite_link.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crash reports from release builds only; debug runs never send anything.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    kReleaseMode,
  );
  final crashReporter = CrashlyticsReporter();
  installErrorReporting(crashReporter);

  await configureDependencies(crashReporter: crashReporter);
  // A group invite waiting from a link or from installing through one.
  await PendingInvite.load();
  unawaited(PendingInvite.checkInstallReferrer());
  runApp(const CampusApp());
}
