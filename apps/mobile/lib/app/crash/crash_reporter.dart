import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

/// Sends crashes and unexpected errors somewhere we can see them.
/// Privacy: no user id, email or profile data is ever attached.
abstract interface class CrashReporter {
  void recordError(Object error, StackTrace? stack, {bool fatal = false});
  void recordFlutterError(FlutterErrorDetails details);
}

/// Firebase Crashlytics. Collection is switched on in release builds only
/// (see main.dart), so debug runs never send anything.
class CrashlyticsReporter implements CrashReporter {
  CrashlyticsReporter([FirebaseCrashlytics? crashlytics])
    : _c = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _c;

  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) {
    _c.recordError(error, stack, fatal: fatal);
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    _c.recordFlutterFatalError(details);
  }
}

/// Keeps errors in memory (tests).
class MemoryCrashReporter implements CrashReporter {
  final errors = <(Object, bool)>[];

  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) =>
      errors.add((error, fatal));

  @override
  void recordFlutterError(FlutterErrorDetails details) =>
      errors.add((details.exception, true));
}

/// Routes every uncaught error to [reporter]: framework errors, errors
/// outside Flutter (async, platform channels) and bloc errors. An image
/// that fails to load (a map tile, a photo) is not a crash: offline ones
/// aren't reported at all, others as non-fatal.
void installErrorReporting(CrashReporter reporter) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details); // still visible in the console
    if (isImageLoadError(details)) {
      if (!isNetworkError(details.exception)) {
        reporter.recordError(details.exception, details.stack);
      }
      return;
    }
    reporter.recordFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, fatal: true);
    return true;
  };
  Bloc.observer = AppBlocObserver(reporter);
}

/// Blocs report unexpected errors with addError; send them on (non-fatal).
class AppBlocObserver extends BlocObserver {
  AppBlocObserver(this._reporter);

  final CrashReporter _reporter;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _reporter.recordError(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

/// A failed image load (map tiles, photos): Flutter reports these through
/// FlutterError, but the app keeps working (the image stays blank).
bool isImageLoadError(FlutterErrorDetails d) =>
    d.library == 'image resource service';

/// No connection, or the connection broke: expected on a phone.
bool isNetworkError(Object e) =>
    e is SocketException ||
    e is HttpException ||
    e is HandshakeException ||
    e is TimeoutException ||
    e is http.ClientException;
