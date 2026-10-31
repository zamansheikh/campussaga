import 'package:campus_ui/campus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> found(String text) => [
    for (final l in CsLinks.find(text)) l.uri.toString(),
  ];

  test('web addresses, with or without https:// or www.', () {
    expect(found('Form: https://forms.gle/abc123, due Sunday.'), [
      'https://forms.gle/abc123',
    ]);
    expect(found('See www.ju.ac.bd/notice?id=4.'), [
      'https://www.ju.ac.bd/notice?id=4',
    ]);
    expect(found('Register at ju.ac.bd/admission or bit.ly/x9'), [
      'https://ju.ac.bd/admission',
      'https://bit.ly/x9',
    ]);
    expect(found('(details: varsitykotha.com/join/ABCDEF)'), [
      'https://varsitykotha.com/join/ABCDEF',
    ]);
    expect(found('https://en.wikipedia.org/wiki/Dhaka_(city)'), [
      'https://en.wikipedia.org/wiki/Dhaka_(city)',
    ]);
  });

  test('emails and Bangladeshi mobile numbers', () {
    expect(found('Mail cr.cse40@gmail.com or call 01712345678.'), [
      'mailto:cr.cse40@gmail.com',
      'tel:01712345678',
    ]);
    expect(found('Driver: +8801812345678'), ['tel:+8801812345678']);
  });

  test('ordinary text has no links', () {
    expect(found('e.g. Room 3.5, CSE 311, B.Sc. 2nd year, 4:30 PM'), isEmpty);
    expect(found('Roll 2015012345 and 123456789012'), isEmpty);
    expect(found('Lab 2 projector is broken.'), isEmpty);
  });

  testWidgets('a tapped link is opened; plain text stays plain', (
    tester,
  ) async {
    final opened = <Uri>[];
    CsLinkText.onOpen = (_, uri) => opened.add(uri);
    addTearDown(() => CsLinkText.onOpen = null);
    await tester.pumpWidget(
      MaterialApp(
        theme: CsTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              CsLinkText('Quiz form: forms.gle/abc'),
              CsLinkText('No links here'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('No links here'), findsOneWidget);
    await tester.tapOnText(find.textRange.ofSubstring('forms.gle/abc'));
    expect(opened, [Uri.parse('https://forms.gle/abc')]);
  });
}
