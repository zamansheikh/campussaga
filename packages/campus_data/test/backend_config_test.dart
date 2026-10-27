import 'package:campus_data/campus_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend is skipped when env values are missing', () async {
    const config = BackendConfig(url: '', publishableKey: '');
    expect(config.isConfigured, isFalse);

    await Backend.init(config);
    expect(Backend.isReady, isFalse);
  });
}
