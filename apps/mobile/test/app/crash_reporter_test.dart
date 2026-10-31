import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:varsitykotha/app/crash/crash_reporter.dart';

class _Boom extends Cubit<int> {
  _Boom() : super(0);
  void fail() => addError(StateError('bug'), StackTrace.current);
}

void main() {
  test('errors a bloc reports reach the crash reporter (non-fatal)', () async {
    final reporter = MemoryCrashReporter();
    final previous = Bloc.observer;
    Bloc.observer = AppBlocObserver(reporter);
    addTearDown(() => Bloc.observer = previous);

    _Boom().fail();
    expect(reporter.errors.single.$1, isA<StateError>());
    expect(reporter.errors.single.$2, isFalse);
  });

  test('an image that fails to load offline is not a crash', () {
    final reporter = MemoryCrashReporter();
    final previous = FlutterError.onError;
    installErrorReporting(reporter);
    addTearDown(() => FlutterError.onError = previous);
    void report(Object e, {String library = 'image resource service'}) =>
        FlutterError.onError!(
          FlutterErrorDetails(exception: e, library: library, silent: true),
        );

    // A map tile while offline: not reported.
    report(http.ClientException('Network is unreachable'));
    report(const SocketException('Connection failed'));
    expect(reporter.errors, isEmpty);

    // Another image problem: reported, but not as a crash.
    report(StateError('bad image data'));
    expect(reporter.errors.single.$2, isFalse);

    // Anything else is still a crash.
    report(StateError('bug'), library: 'widgets library');
    expect(reporter.errors.last.$2, isTrue);
  });
}
