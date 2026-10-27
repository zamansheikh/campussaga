import 'package:campus_core/campus_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses /config and tolerates missing or odd values', () {
    final c = AppConfig.fromJson({
      'minSupportedBuild': 3,
      'storeUrls': {'android': 'https://play.google.com/x', 'ios': null},
      'features': {'myClass': true, 'odd': 'yes'},
      'unknownKey': 1,
    });
    expect(c.minSupportedBuild, 3);
    expect(c.storeUrls, {'android': 'https://play.google.com/x'});
    expect(c.features, {'myClass': true});
    expect(c.isSupported(2), isFalse);
    expect(c.isSupported(3), isTrue);
    expect(AppConfig.fromJson({}).isSupported(1), isTrue);
  });
}
