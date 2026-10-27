import 'package:campus_data/campus_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connects only when an env file with backend values is passed in.
  await Backend.init(
    const BackendConfig(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    ),
  );

  runApp(const ProviderScope(child: CampusApp()));
}
