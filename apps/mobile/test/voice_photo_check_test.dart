import 'package:campus_core/campus_core.dart';
import 'package:campus_l10n/campus_l10n.dart';
import 'package:campussaga/features/voice/presentation/voice_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bn = lookupAppLocalizations(const Locale('bn'));

  test('posts held by the photo check say so, in English and Bangla', () {
    for (final reason in ['photo_check', 'photo_check_unavailable']) {
      expect(holdReasonText(en, reason), en.voiceHeldPhoto);
      expect(holdReasonText(bn, reason), isNotEmpty);
    }
  });

  testWidgets('a refused photo gets a plain message', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    const f = RejectedFailure(code: 'PHOTO_NOT_ALLOWED');
    expect(
      voiceErrorText(ctx, f),
      "This photo can't be posted. Choose another photo.",
    );
  });
}
