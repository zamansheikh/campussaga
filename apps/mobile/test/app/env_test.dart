import 'package:flutter_test/flutter_test.dart';
import 'package:varsitykotha/app/env.dart';

void main() {
  test('debug builds without an env file use the local backend', () {
    // Tests run without --dart-define, like the editor's Run button.
    expect(Env.apiBaseUrl, Env.localApiBaseUrl);
    expect(Env.apiBaseUrl, startsWith('http://localhost:8090'));
  });
}
