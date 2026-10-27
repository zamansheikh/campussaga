import 'package:campus_l10n/campus_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Bangla are supported', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'bn']),
    );
  });

  test('Bangla strings are really translated', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final bn = await AppLocalizations.delegate.load(const Locale('bn'));
    expect(bn.navToday, isNot(en.navToday));
    expect(bn.todayEmptyTitle, isNot(en.todayEmptyTitle));
  });
}
