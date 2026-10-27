import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const CampusApp());
}
