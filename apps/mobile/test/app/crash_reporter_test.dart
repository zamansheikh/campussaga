import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
